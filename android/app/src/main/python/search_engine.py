"""
Simple search engine (keyword-based)
"""

def search_documents(data_dir, query):
    """Search indexed documents by keywords"""
    try:
        if not query or len(query.strip()) < 2:
            return {"results": []}

        import os
        import json

        query_lower = query.lower().split()
        results = []

        # Search in index file
        index_file = os.path.join(data_dir, 'document_index.json')
        if os.path.exists(index_file):
            with open(index_file, 'r') as f:
                index = json.load(f)

                for doc_path, content in index.items():
                    content_lower = content.lower()
                    matches = sum(1 for q in query_lower if q in content_lower)
                    if matches > 0:
                        results.append(doc_path)

        return {"results": results[:20]}  # Limit to 20 results

    except Exception as e:
        print(f"Search error: {e}")
        return {"results": []}

def add_to_index(data_dir, file_path, content):
    """Add document to search index"""
    try:
        import os
        import json

        index_file = os.path.join(data_dir, 'document_index.json')

        # Load existing index
        index = {}
        if os.path.exists(index_file):
            with open(index_file, 'r') as f:
                index = json.load(f)

        # Add new document
        index[file_path] = content[:1000]  # Store first 1000 chars

        # Save index
        with open(index_file, 'w') as f:
            json.dump(index, f)

        print(f"Indexed: {file_path}")

    except Exception as e:
        print(f"Indexing error: {e}")
