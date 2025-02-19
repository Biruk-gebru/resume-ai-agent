from fastapi import FastAPI
from app.routes import router as resume_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Resume AI Optimizer")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development; restrict to specific origins in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include routes from our routes file
app.include_router(resume_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
