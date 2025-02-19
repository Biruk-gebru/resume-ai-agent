
---

# Resume AI Agent

This project is an AI-powered resume optimizer that lets users upload their resume (in DOCX format), extract the text, and then optimize the resume based on a given job description. The backend is built using FastAPI and Supabase for storage, while the frontend is implemented in Flutter.

> **Note:**  
> - The optimized resume output is generated as a plain text (.txt) file and is unformatted.  
> - Due to complications with using a `.env` file, the API key and URL settings for external services have been left blank in the source code. You will need to manually fill in these values or modify the configuration as needed.

## Features

- **Resume Upload:**  
  Users can upload DOCX resumes. The backend extracts and stores the resume text in a Supabase database.

- **Resume Optimization:**  
  Given a job description, the system finds the best matching resume from the database and then optimizes it using an external API.  
  *The output is provided as plain text (.txt) without any formatting.*

- **Download Optimized Resume:**  
  Users have the option to download the optimized resume as a TXT file.

## Tech Stack

- **Backend:** FastAPI, Python, Supabase  
- **Frontend:** Flutter, Dart  
- **API Integration:** Azure Inference API (via `azure-ai-inference` package)

## Setup

### Prerequisites

- Python 3.10+  
- Flutter (latest stable or master channel, as needed)  
- Supabase account (for database storage)  
- External API credentials (if using an inference service)

### Backend Setup

1. **Clone the Repository:**

   ```bash
   git clone https://your-repo-url.git
   cd your-repo-directory
   ```

2. **Create and Activate a Virtual Environment:**

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables:**

   Although the project uses `python-dotenv`, due to complications with using a `.env` file the API settings have been left blank in the code. Open `app/config.py` and manually fill in:
   
   ```python
   SUPABASE_URL = ""  # Insert your Supabase URL here
   SUPABASE_API_KEY = ""  # Insert your Supabase API key here
   ```
   Additionally, the AI-related APIs used in this project were sourced from the GitHub Marketplace, where anyone can find similar APIs and generate their own tokens. The API key fields related to AI services will also be left empty, requiring users to obtain and insert their own credentials.
   Likewise, adjust any API configuration as needed.

5. **Run the FastAPI Server:**

   ```bash
   uvicorn app.main:app --reload
   ```

### Flutter Frontend Setup

1. **Clone the Flutter Project:**

   Navigate to the Flutter project directory (e.g., `resume_ai_app`).

2. **Install Dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint URLs:**

   In your Flutter code (e.g., in `lib/main.dart`), ensure the API URLs point to your FastAPI backend (for local testing, use `http://localhost:8000/api/...`).

4. **Run the App:**

   ```bash
   flutter run
   ```

## How It Works

1. **Upload Resume:**  
   - Users upload a DOCX file.  
   - The backend extracts the text and stores it in the Supabase database.

2. **Find & Optimize Resume:**  
   - Users enter a job description.  
   - The system finds the best matching resume from the stored resumes and displays it.  
   - Users can then click "Optimize This Resume" to generate an optimized version.  
   - The optimized output is generated as an unformatted TXT file.

3. **Download Optimized Resume:**  
   - After optimization, users can download the TXT file containing the optimized resume.

## Limitations & Future Improvements

- **Unformatted Output:**  
  The current implementation outputs plain text with no formatting. Future updates may include generating DOCX or PDF files with improved formatting.
  
- **API Configuration:**  
  API keys and endpoints are left blank due to `.env` issues. Future work will address a more robust configuration management system.

- **Better Matching:**  
  The current matching algorithm is simplistic (e.g., using basic token overlap). Consider integrating more advanced methods (e.g., embedding similarity) for improved resume selection.

y further modifications or additional sections!
