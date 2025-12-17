import os
import traceback


def read_file(file_path):
    print(f"DEBUG: Python reading file: {file_path}")

    try:
        if not file_path:
            return {"content": ""}

        file_path = file_path.strip()

        if not os.path.exists(file_path):
            print(f"DEBUG: File does not exist at path: {file_path}")
            return {"content": ""}

        if file_path.lower().endswith('.pdf'):
            try:
                print("DEBUG: Attempting to read PDF with pypdf...")
                from pypdf import PdfReader

                with open(file_path, 'rb') as f:
                    pdf = PdfReader(f)
                    text = ''
                    num_pages = len(pdf.pages)
                    print(f"DEBUG: PDF has {num_pages} pages")

                    for i, page in enumerate(pdf.pages[:15]):
                        extracted = page.extract_text()
                        if extracted:
                            text += extracted + "\n"

                    print(f"DEBUG: Extracted {len(text)} chars from PDF")
                    return {"content": text[:10000]}
            except Exception as e:
                print(f"DEBUG: PDF reading error: {e}")
                traceback.print_exc()
                return {"content": ""}

        elif file_path.lower().endswith('.docx'):
            try:
                print("DEBUG: Attempting to read DOCX...")
                from docx import Document
                doc = Document(file_path)
                text = '\n'.join([p.text for p in doc.paragraphs])
                print(f"DEBUG: Extracted {len(text)} chars from DOCX")
                return {"content": text[:10000]}
            except Exception as e:
                print(f"DEBUG: DOCX reading error: {e}")
                traceback.print_exc()
                return {"content": ""}

        elif file_path.lower().endswith((
                '.txt', '.md', '.csv',
                '.py', '.dart', '.java', '.kt', '.swift',
                '.c', '.cpp', '.h', '.cs',
                '.js', '.ts', '.html', '.css',
                '.json', '.xml', '.yaml', '.yml',
                '.sql', '.properties', '.gradle', '.sh', '.bat'
        )):
            try:
                print("DEBUG: Reading as text/code file...")
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    print(f"DEBUG: Extracted {len(content)} chars")
                    return {"content": content[:10000]}
            except Exception as e:
                print(f"DEBUG: Text reading error: {e}")
                return {"content": ""}

        else:
            print(f"DEBUG: Unsupported file type for text extraction: {file_path}")
            return {"content": ""}

    except Exception as e:
        print(f"DEBUG: Critical file reading error: {e}")
        traceback.print_exc()
        return {"content": ""}
