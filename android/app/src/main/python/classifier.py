import os
import json
import numpy as np
import re

# Global Cache
_vocab = None
_word_vectors = None
_topic_vectors = None

# MATCHING STOPWORDS LIST (Critical for accuracy)
STOPWORDS = {
    'the', 'and', 'to', 'of', 'a', 'in', 'is', 'that', 'for', 'it', 'on', 'with', 'as',
    'was', 'at', 'by', 'an', 'be', 'this', 'which', 'or', 'from', 'but', 'not', 'are',
    'your', 'all', 'have', 'new', 'more', 'an', 'was', 'we', 'will', 'home', 'can',
    'us', 'about', 'if', 'page', 'my', 'has', 'search', 'free', 'but', 'our', 'one',
    'other', 'do', 'no', 'information', 'time', 'they', 'site', 'he', 'up', 'may',
    'what', 'which', 'their', 'news', 'out', 'use', 'any', 'there', 'see', 'only',
    'so', 'his', 'when', 'contact', 'here', 'business', 'who', 'web', 'also', 'now',
    'help', 'get', 'pm', 'view', 'online', 'c', 'e', 'first', 'am', 'been', 'would',
    'how', 'were', 'me', 's', 'services', 'some', 'these', 'click', 'its', 'like',
    'service', 'x', 'than', 'find', 'price', 'date', 'back', 'top', 'people', 'had',
    'list', 'name', 'just', 'over', 'state', 'year', 'day', 'into', 'email', 'two',
    'health', 'n', 'world', 're', 'next', 'used', 'go', 'b', 'work', 'last', 'most'
}

def load_resources(asset_path):
    global _vocab, _word_vectors, _topic_vectors
    if _vocab is None:
        try:
            print(f"DEBUG: Loading model from {asset_path}...")
            with open(os.path.join(asset_path, "vocab.json"), "r") as f:
                _vocab = json.load(f)
            _word_vectors = np.load(os.path.join(asset_path, "word_vectors.npy"))
            _topic_vectors = np.load(os.path.join(asset_path, "topic_vectors.npy"))
            return True
        except Exception as e:
            print(f"CRITICAL ERROR loading model: {e}")
            return False
    return True

def simple_preprocess(text):
    """Tokenize and REMOVE STOPWORDS"""
    # 1. Split by non-word characters
    tokens = re.findall(r'\b[a-z]{3,}\b', text.lower())
    # 2. Filter out stopwords (The fix!)
    return [t for t in tokens if t not in STOPWORDS]

def infer_vector_manual(words):
    global _vocab, _word_vectors
    vectors = []
    for word in words:
        if word in _vocab:
            idx = _vocab[word]
            vectors.append(_word_vectors[idx])

    if not vectors: return None
    return np.mean(vectors, axis=0)

def classify_file(asset_path, text_content):
    if not text_content or len(text_content.strip()) < 5:
        return {"topic_number": -1, "confidence": 0.0}

    if not load_resources(asset_path):
        return {"topic_number": -1, "confidence": 0.0}

    tokens = simple_preprocess(text_content)
    if not tokens:
        return {"topic_number": -1, "confidence": 0.0}

    doc_vector = infer_vector_manual(tokens)
    if doc_vector is None:
        return {"topic_number": -1, "confidence": 0.0}

    norm_doc = np.linalg.norm(doc_vector)
    if norm_doc == 0: return {"topic_number": -1, "confidence": 0.0}

    scores = np.dot(_topic_vectors, doc_vector) / (np.linalg.norm(_topic_vectors, axis=1) * norm_doc)
    best_topic_id = int(np.argmax(scores))
    confidence = float(scores[best_topic_id])

    print(f"DEBUG: Classified as Topic {best_topic_id} with conf {confidence:.2f}")
    return {"topic_number": best_topic_id, "confidence": confidence}