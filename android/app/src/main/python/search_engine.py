"""
On-Device Training Search Engine using Gensim/Doc2Vec
"""
import os
import json
import numpy as np
import traceback
from gensim.models.doc2vec import Doc2Vec, TaggedDocument
from gensim.utils import simple_preprocess

# Global cache
_model = None

print("DEBUG: search_engine module loaded successfully")

def _get_model_path(data_dir):
    # Ensure the models directory exists
    models_dir = os.path.join(data_dir, "models")
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)
    return os.path.join(models_dir, "local_search_model.d2v")

def _load_resources(data_dir):
    """Load the locally trained model if it exists"""
    global _model

    # Always try to reload if model is None (it might have just finished training)
    if _model is None:
        model_path = _get_model_path(data_dir)
        if os.path.exists(model_path):
            try:
                print(f"DEBUG: Loading local search model from {model_path}...")
                _model = Doc2Vec.load(model_path)
                print(f"DEBUG: Local model loaded successfully. Vocab: {len(_model.wv.key_to_index)}")
            except Exception as e:
                print(f"DEBUG: Error loading local model: {e}")
                _model = None
        else:
            # Silent fail is fine, user hasn't trained yet
            pass

def train_local_index(data_dir, json_data_str):
    """
    Train a Doc2Vec model on the device using the provided documents.
    json_data_str: String containing JSON { "file_path": "file_content" }
    """
    global _model
    print("DEBUG: train_local_index called")

    try:
        # FIX: Decode JSON string to native Python dictionary
        # This bypasses all Java Map iteration issues
        py_file_map = json.loads(json_data_str)

        print(f"DEBUG: Starting on-device training with {len(py_file_map)} docs...")

        # ... rest of the logic is identical ...
        if not py_file_map:
            print("DEBUG: Training aborted - empty map")
            return {"status": "empty"}

        # 1. Prepare Training Data
        tagged_data = []
        valid_doc_count = 0

        for path, content in py_file_map.items():
            if not content: continue

            tokens = simple_preprocess(str(content))
            if tokens:
                tagged_data.append(TaggedDocument(words=tokens, tags=[path]))
                valid_doc_count += 1

        if not tagged_data:
            print("DEBUG: No valid tokens found for training.")
            return {"status": "no_tokens"}

        print(f"DEBUG: Prepared {valid_doc_count} docs for training.")

        # 2. Configure & Train Model
        model = Doc2Vec(vector_size=20, min_count=1, epochs=20)
        model.build_vocab(tagged_data)

        vocab_len = len(model.wv.key_to_index)
        print(f"DEBUG: Training on vocab size: {vocab_len}")

        model.train(tagged_data, total_examples=model.corpus_count, epochs=model.epochs)

        # 3. Save Model Locally
        save_path = _get_model_path(data_dir)
        model.save(save_path)
        print(f"DEBUG: Model saved to {save_path}")

        # 4. Update Memory immediately
        _model = model

        return {"status": "success", "vocab_size": vocab_len}

    except Exception as e:
        print(f"DEBUG: CRITICAL TRAINING ERROR: {e}")
        import traceback
        traceback.print_exc()
        return {"status": "error", "message": str(e)}

def search_documents(data_dir, query):
    """
    Perform semantic search using the locally trained model
    """
    try:
        _load_resources(data_dir)

        if _model is None:
            print("DEBUG: No local model found. Search unavailable.")
            return {"results": []}

        if not query or len(query.strip()) < 2:
            return {"results": []}

        query_tokens = simple_preprocess(query)
        print(f"DEBUG: Search Query Tokens: {query_tokens}")

        # Check if ANY word is in vocab (to avoid 0-vector issues)
        if not any(token in _model.wv.key_to_index for token in query_tokens):
            print(f"DEBUG: Unknown words: {query_tokens}")
            return {"results": []}

        # Infer vector for query
        query_vector = _model.infer_vector(query_tokens)

        # Find most similar documents
        sims = _model.dv.most_similar([query_vector], topn=10)

        results = []
        for path, score in sims:
            print(f"DEBUG: Match: {path} (Score: {score})")
            if score > 0.0: # Accept everything for debug
                results.append(path)

        return {"results": results}

    except Exception as e:
        print(f"DEBUG: Search error: {e}")
        return {"results": []}