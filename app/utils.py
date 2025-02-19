import docx2txt

def process_docx_file(file_path: str) -> str:
    """
    Process the .docx file and extract text.
    """
    text = docx2txt.process(file_path)
    return text
