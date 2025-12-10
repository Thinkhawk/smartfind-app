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
        # FIX: Point to the 'models' subdirectory where assets are actually stored
        models_dir = os.path.join(app_files_dir, "models")

        # Load the brain
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

        # Save the search index in the root files dir (or models dir, doesn't matter much)
        # Keeping it in root is fine.
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
        # FIX: Point to the 'models' subdirectory
        models_dir = os.path.join(app_files_dir, "models")

        # 1. Load Brain
        if not classifier.load_resources(models_dir):
            return {"results": []}

        # 2. Load Index
        index_path = os.path.join(app_files_dir, "search_index.json")
        if not os.path.exists(index_path):
            return {"results": []}

        with open(index_path, "r") as f:
            index_data = json.load(f)

        # 3. Vectorize Query
        query_tokens = classifier.simple_preprocess(query)
        query_vec = classifier.infer_vector_manual(query_tokens)

        if query_vec is None:
            return {"results": []}

        # Normalize query
        query_norm = np.linalg.norm(query_vec)
        if query_norm == 0: return {"results": []}
        query_vec = query_vec / query_norm

        # 4. Compare
        results = []
        for item in index_data:
            doc_vec = np.array(item['vector'])
            score = np.dot(query_vec, doc_vec)

            if score > 0.3: # Threshold
                results.append((item['path'], score))

        # Sort by score
        results.sort(key=lambda x: x[1], reverse=True)

        return {"results": [r[0] for r in results[:10]]}

    except Exception as e:
        print(f"Search Error: {e}")
        return {"results": []}