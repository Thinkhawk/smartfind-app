"""
Read file content (supports PDF, DOCX, TXT)
"""

def read_file(file_path):
    """Read file and extract text"""
    try:
        if not file_path:
            return {"content": ""}

        file_path = file_path.strip()

        # Text files
        if file_path.endswith(('.txt', '.md')):
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                return {"content": content[:5000]}  # Limit to 5000 chars

        # PDF files
        elif file_path.endswith('.pdf'):
            try:
                from PyPDF2 import PdfReader
                with open(file_path, 'rb') as f:
                    pdf = PdfReader(f)
                    text = ''
                    for page in pdf.pages[:10]:  # First 10 pages
                        text += page.extract_text()
                    return {"content": text[:5000]}
            except Exception as e:
                print(f"PDF reading error: {e}")
                return {"content": ""}

        # DOCX files
        elif file_path.endswith('.docx'):
            try:
                from docx import Document
                doc = Document(file_path)
                text = '\n'.join([p.text for p in doc.paragraphs])
                return {"content": text[:5000]}
            except Exception as e:
                print(f"DOCX reading error: {e}")
                return {"content": ""}

        else:
            # Try reading as text
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                return {"content": content[:5000]}

    except Exception as e:
        print(f"File reading error: {e}")
        return {"content": ""}
