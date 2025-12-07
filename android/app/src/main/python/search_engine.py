"""
On-Device Search Engine: Semantic (Doc2Vec) - Incremental Learning
"""
import os
import json
import traceback
from gensim.models.doc2vec import Doc2Vec, TaggedDocument
from gensim.utils import simple_preprocess

# Global cache
_model = None

print("DEBUG: search_engine module loaded successfully")

def _get_model_path(data_dir):
    models_dir = os.path.join(data_dir, "models")
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)
    return os.path.join(models_dir, "local_search_model.d2v")

def _load_resources(data_dir):
    """Load the locally trained model if it exists"""
    global _model
    if _model is None:
        model_path = _get_model_path(data_dir)
        if os.path.exists(model_path):
            try:
                _model = Doc2Vec.load(model_path)
                print(f"DEBUG: Semantic model loaded. Docs: {len(_model.dv)}")
            except Exception as e:
                print(f"DEBUG: Error loading semantic model: {e}")
                _model = None

def get_indexed_paths(data_dir):
    """Return a list of file paths that are already in the model"""
    _load_resources(data_dir)
    if _model is None:
        return {"paths": []}

    # gensim 4.x stores tags in dv.index_to_key
    return {"paths": list(_model.dv.index_to_key)}

def train_local_index(data_dir, json_data_str):
    """
    Train OR Update Doc2Vec model on device.
    """
    global _model
    print("DEBUG: train_local_index called")

    try:
        py_file_map = json.loads(json_data_str)
        print(f"DEBUG: Received {len(py_file_map)} docs for training...")

        if not py_file_map:
            return {"status": "empty"}

        # Prepare Training Data
        tagged_data = []
        for path, content in py_file_map.items():
            if not content: continue

            tokens = simple_preprocess(str(content))
            if tokens:
                tagged_data.append(TaggedDocument(words=tokens, tags=[path]))

        if not tagged_data:
            return {"status": "no_tokens"}

        # Load existing model to check if we can do an UPDATE
        _load_resources(data_dir)
        model_path = _get_model_path(data_dir)

        if _model is None:
            # --- SCENARIO A: FRESH TRAIN (First time) ---
            print("DEBUG: No existing model. Training from scratch...")
            model = Doc2Vec(vector_size=50, min_count=1, epochs=20)
            model.build_vocab(tagged_data)
            model.train(tagged_data, total_examples=model.corpus_count, epochs=model.epochs)
            _model = model

        else:
            # --- SCENARIO B: INCREMENTAL UPDATE (Adding new files) ---
            print("DEBUG: Updating existing model...")
            # update=True adds new words and new document tags to the model
            _model.build_vocab(tagged_data, update=True)

            # Train only on the new data
            # total_examples needs to be the count of the NEW batch
            _model.train(tagged_data, total_examples=len(tagged_data), epochs=_model.epochs)

        # Save Updated Model
        _model.save(model_path)
        print(f"DEBUG: Model saved. Total Indexed Docs: {len(_model.dv)}")

        return {"status": "success", "vocab_size": len(_model.wv.key_to_index)}

    except Exception as e:
        print(f"DEBUG: TRAINING ERROR: {e}")
        traceback.print_exc()
        return {"status": "error", "message": str(e)}

def search_documents(data_dir, query):
    """Perform semantic search"""
    try:
        _load_resources(data_dir)

        if _model is None or not query:
            return {"results": []}

        query_tokens = simple_preprocess(query)

        # Check if model knows these words
        if not any(token in _model.wv.key_to_index for token in query_tokens):
            return {"results": []}

        query_vector = _model.infer_vector(query_tokens)
        sims = _model.dv.most_similar([query_vector], topn=10)

        results = [path for path, score in sims if score > 0.3]
        return {"results": results}

    except Exception as e:
        print(f"Semantic Search error: {e}")
        return {"results": []}