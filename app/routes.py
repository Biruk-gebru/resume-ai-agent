from fastapi import APIRouter, UploadFile, File, Form
from fastapi.responses import JSONResponse
import docx2txt
import os
from app.utils import process_docx_file
from app.db import supabase
import httpx
from app.config import SUPABASE_API_KEY, SUPABASE_URL
from openai import OpenAI
import torch
from transformers import GPT2LMHeadModel, GPT2Tokenizer
from fastapi import APIRouter, Form
from fastapi.responses import JSONResponse
from app.db import supabase
from dotenv import load_dotenv  
import os  

# Load environment variables from the .env file  
load_dotenv()  


router = APIRouter()
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0" 

@router.get("/health")
async def health():
    return {"msg": "hello world"}

@router.post("/upload-resume")
async def upload_resume(file: UploadFile = File(...)):
    if file.content_type != "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
        return JSONResponse(status_code=400, content={"message": "Only .docx files are supported."})
    
    # Save the uploaded file temporarily
    file_location = f"temp_{file.filename}"
    with open(file_location, "wb") as f:
        f.write(await file.read())
    
    # Process file with docx2txt
    resume_text = process_docx_file(file_location)
    os.remove(file_location)
    
    # Insert the resume into Supabase (only storing resume_content for now)
    data = {"resume_content": resume_text}
    

    try:
        response = supabase.table("resume").insert(data).execute()
    except Exception as e:
        print("Supabase insert error:", e)
        return JSONResponse(status_code=500, content={"message": "Error inserting resume into database.", "details": str(e)})
    
    return JSONResponse(status_code=200, content={"message": "Resume processed and stored successfully.", "content": resume_text})




# router = APIRouter()

@router.post("/optimize-resume")
async def optimize_resume(job_description: str = Form(...), resume_content: str = Form(...)):
    """
    Endpoint to optimize a resume using an external API via the OpenAI SDK.
    The API is called with a system message to set context and a user message that includes
    the job description and resume content. The optimized resume is then stored in Supabase.
    """
    # Construct the messages for the chat completion
    system_message = {
        "role": "system",
        "content": "You are a helpful assistant that optimizes resumes for job applications."
    }
    user_message = {
        "role": "user",
        "content": (
            f"Optimize this resume for the following job description, only give me the optmized resume as an output(no need for explanatory text from youw):\n\n"
            f"Job Description: {job_description}\n\n"
            f"Resume: {resume_content}"
        )
    }
    
    try:
        # Initialize the client with the given API endpoint and token.
        client = OpenAI(
            base_url="https://models.inference.ai.azure.com",
            api_key="",  # Ensure your PAT is set as GITHUB_TOKEN
        )

        
        try:# Call the chat completion endpoint using the new API
            response = client.chat.completions.create(
                messages=[system_message, user_message],
                model="gpt-4o",
                temperature=1,
                max_tokens=4096,
                top_p=1
            )
        except Exception as e:
            print("error: ", e)
            return {"error:", str(e)}
    
        
        # Extract the optimized resume from the response
        optimized_resume = response.choices[0].message.content
        
        # Insert the job description, original resume, and optimized resume into Supabase
        data = {
            "job_description": job_description,
            "resume_content": resume_content,
            "optimized_resume": optimized_resume
        }
        supabase_response = supabase.table("resume").insert(data).execute()
        print(supabase_response)
        
        return JSONResponse(status_code=200, content={"optimized_resume": optimized_resume})
    
    except Exception as e:
        print("Error optimizing resume:", e)
        return JSONResponse(
            status_code=500,
            content={"message": "Error optimizing resume.", "details": str(e)}
        )

@router.post("/best-resume")
async def best_resume(job_description: str = Form(...)):
    """
    Finds the best fitting resume from the database based on the job description.
    Uses a simple token overlap (Jaccard similarity) metric.
    """
    try:
        result = supabase.table("resume").select("*").execute()
        resumes = result.data  # list of resume records from Supabase
        if not resumes:
            return JSONResponse(status_code=404, content={"message": "No resumes found in the database."})
        
        # Define a simple similarity function using Jaccard similarity.
        def similarity(job, resume):
            job_tokens = set(job.lower().split())
            resume_tokens = set(resume.lower().split())
            if not job_tokens or not resume_tokens:
                return 0
            return len(job_tokens.intersection(resume_tokens)) / len(job_tokens.union(resume_tokens))
        
        best_resume = None
        best_score = -1
        for record in resumes:
            text = record.get("resume_content", "")
            score = similarity(job_description, text)
            if score > best_score:
                best_score = score
                best_resume = record
        
        if best_resume:
            return JSONResponse(
                status_code=200,
                content={
                    "best_resume": best_resume.get("resume_content"),
                    "score": best_score
                }
            )
        else:
            return JSONResponse(status_code=404, content={"message": "No suitable resume found."})
    
    except Exception as e:
        print("Error finding best resume:", e)
        return JSONResponse(status_code=500, content={"message": "Error retrieving resumes.", "details": str(e)})
