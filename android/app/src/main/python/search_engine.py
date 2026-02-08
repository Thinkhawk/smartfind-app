import os
import json
import numpy as np
import re
import classifier


def train_local_index(app_files_dir, documents_json):
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


def get_similar_files(app_files_dir, file_path):
    try:
        index_path = os.path.join(app_files_dir, "search_index.json")
        if not os.path.exists(index_path):
            return {"results": []}

        with open(index_path, "r") as f:
            index_data = json.load(f)

        target_vec = None
        for item in index_data:
            if item['path'] == file_path:
                target_vec = np.array(item['vector'])
                break

        if target_vec is None:
            print(f"DEBUG: File not found in index: {file_path}")
            return {"results": []}

        results = []
        for item in index_data:
            if item['path'] == file_path: continue  # Skip self

            doc_vec = np.array(item['vector'])
            score = np.dot(target_vec, doc_vec)

            if score > 0.1:
                results.append((item['path'], score))

        results.sort(key=lambda x: x[1], reverse=True)

        top_results = [r[0] for r in results[:5]]
        print(f"DEBUG: Semantic recommendations for {file_path}: {top_results}")

        return {"results": top_results}

    except Exception as e:
        print(f"Similarity Error: {e}")
        return {"results": []}

def remove_from_index(app_files_dir, file_path):
    """
    Removes a specific file entry from the semantic search index.
    """
    try:
        index_path = os.path.join(app_files_dir, "search_index.json")
        if not os.path.exists(index_path):
            return {"status": "error", "message": "Index not found"}

        with open(index_path, "r") as f:
            index_data = json.load(f)

        # Create a new list excluding the deleted file path
        initial_count = len(index_data)
        index_data = [item for item in index_data if item['path'] != file_path]

        # Only write if a change was actually made
        if len(index_data) < initial_count:
            with open(index_path, "w") as f:
                json.dump(index_data, f)
            print(f"DEBUG: Successfully removed {file_path} from index.")
            return {"status": "success", "count": len(index_data)}

        return {"status": "no_change"}
    except Exception as e:
        print(f"DEBUG: Error removing from index: {e}")
        return {"status": "error", "message": str(e)}