import os
import json
import numpy as np
import re
from java.util import ArrayList

# Global Cache to keep app fast
_vocab = None
_word_vectors = None
_topic_vectors = None

def load_resources(asset_path):
    """Load raw mathematical weights instead of fragile pickle objects"""
    global _vocab, _word_vectors, _topic_vectors

    if _vocab is None:
        try:
            print(f"DEBUG: Loading safe model assets from {asset_path}...")

            # 1. Load Vocab
            with open(os.path.join(asset_path, "vocab.json"), "r") as f:
                _vocab = json.load(f)

            # 2. Load Word Vectors
            _word_vectors = np.load(os.path.join(asset_path, "word_vectors.npy"))

            # 3. Load Topic Vectors
            _topic_vectors = np.load(os.path.join(asset_path, "topic_vectors.npy"))

            print(f"DEBUG: Model Loaded. Vocab: {len(_vocab)}, Vectors: {_word_vectors.shape}")
            return True
        except Exception as e:
            print(f"CRITICAL ERROR loading model: {e}")
            return False
    return True

def simple_preprocess(text):
    """Simple tokenizer to match Gensim's logic"""
    return [word.lower() for word in re.findall(r'\b\w\w+\b', text)]

def infer_vector_manual(words):
    """
    Manually calculate document vector by averaging word vectors.
    This bypasses the need for the complex Doc2Vec object.
    """
    global _vocab, _word_vectors

    vectors = []
    for word in words:
        if word in _vocab:
            idx = _vocab[word]
            vectors.append(_word_vectors[idx])

    if not vectors:
        return None

    # Average the vectors (Standard approach for lightweight inference)
    return np.mean(vectors, axis=0)

def classify_file(asset_path, text_content):
    """
    Main entry point called by Flutter
    """
    if not text_content or len(text_content.strip()) < 5:
        return {"topic_number": -1, "confidence": 0.0}

    # 1. Load Model
    if not load_resources(asset_path):
        return {"topic_number": -1, "confidence": 0.0}

    # 2. Preprocess
    tokens = simple_preprocess(text_content)
    if not tokens:
        return {"topic_number": -1, "confidence": 0.0}

    # 3. Infer Vector (The "Brain")
    doc_vector = infer_vector_manual(tokens)

    if doc_vector is None:
        # Document contained no known words
        print("DEBUG: No known words in document.")
        return {"topic_number": -1, "confidence": 0.0}

    # 4. Find Closest Topic (Cosine Similarity)
    # Cosine Sim = (A . B) / (||A|| * ||B||)

    # Normalize doc vector
    norm_doc = np.linalg.norm(doc_vector)
    if norm_doc == 0: return {"topic_number": -1, "confidence": 0.0}

    # Calculate similarity against all 50 topics at once
    # topic_vectors should already be normalized during training ideally,
    # but we compute dot product here.

    scores = np.dot(_topic_vectors, doc_vector) / (np.linalg.norm(_topic_vectors, axis=1) * norm_doc)

    best_topic_id = int(np.argmax(scores))
    confidence = float(scores[best_topic_id])

    print(f"DEBUG: Classified as Topic {best_topic_id} with conf {confidence:.2f}")

    return {
        "topic_number": best_topic_id,
        "confidence": confidence
    }