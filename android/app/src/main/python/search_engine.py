import os
import json
import numpy as np
import re
import classifier

def train_local_index(app_files_dir, documents_json):
    """
    Converts file text -> Vectors and saves them.
    """
    try:
        models_dir = os.path.join(app_files_dir, "models")
        if not classifier.load_resources(models_dir):
            print("ERROR: Could not load model for search training")
            return

        docs = json.loads(documents_json)
        index_data = []

        print(f"DEBUG: Indexing {len(docs)} files for search...")

        for path, text in docs.items():
            tokens = classifier.simple_preprocess(text)
            vector = classifier.infer_vector_manual(tokens)

            if vector is not None:
                norm = np.linalg.norm(vector)
                if norm > 0:
                    vector = vector / norm
                    index_data.append({
                        "path": path,
                        "vector": vector.tolist()
                    })

        index_path = os.path.join(app_files_dir, "search_index.json")
        with open(index_path, "w") as f:
            json.dump(index_data, f)

        print(f"DEBUG: Saved search index with {len(index_data)} vectors.")

    except Exception as e:
        print(f"Search Training Error: {e}")

def search_documents(app_files_dir, query):
    """
    Vector Search: Query -> Vector vs Index Vectors
    """
    try:
        models_dir = os.path.join(app_files_dir, "models")
        if not classifier.load_resources(models_dir):
            return {"results": []}

        index_path = os.path.join(app_files_dir, "search_index.json")
        if not os.path.exists(index_path):
            return {"results": []}

        with open(index_path, "r") as f:
            index_data = json.load(f)

        query_tokens = classifier.simple_preprocess(query)
        query_vec = classifier.infer_vector_manual(query_tokens)

        if query_vec is None:
            return {"results": []}

        query_norm = np.linalg.norm(query_vec)
        if query_norm == 0: return {"results": []}
        query_vec = query_vec / query_norm

        results = []
        for item in index_data:
            doc_vec = np.array(item['vector'])
            score = np.dot(query_vec, doc_vec)

            # Threshold for search results
            if score > 0.01:
                results.append((item['path'], score))

        results.sort(key=lambda x: x[1], reverse=True)

        return {"results": [r[0] for r in results[:10]]}

    except Exception as e:
        print(f"Search Error: {e}")
        return {"results": []}

# --- ADDED THIS FUNCTION ---
def get_similar_files(app_files_dir, file_path):
    """
    Finds files semantically similar to the given file path.
    """
    try:
        # 1. Load Index
        index_path = os.path.join(app_files_dir, "search_index.json")
        if not os.path.exists(index_path):
            return {"results": []}

        with open(index_path, "r") as f:
            index_data = json.load(f)

        # 2. Find the vector for the input file
        target_vec = None
        for item in index_data:
            if item['path'] == file_path:
                target_vec = np.array(item['vector'])
                break

        if target_vec is None:
            print(f"DEBUG: File not found in index: {file_path}")
            return {"results": []}

        # 3. Compare against all other files
        results = []
        for item in index_data:
            if item['path'] == file_path: continue # Skip self

            doc_vec = np.array(item['vector'])
            score = np.dot(target_vec, doc_vec)

            # Lower threshold for recommendations to show *something*
            if score > 0.1:
                results.append((item['path'], score))

        # 4. Sort
        results.sort(key=lambda x: x[1], reverse=True)

        # Return top 5
        top_results = [r[0] for r in results[:5]]
        print(f"DEBUG: Semantic recommendations for {file_path}: {top_results}")

        return {"results": top_results}

    except Exception as e:
        print(f"Similarity Error: {e}")
        return {"results": []}