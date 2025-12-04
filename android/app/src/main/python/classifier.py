import os
import numpy as np
from gensim.models.doc2vec import Doc2Vec
from gensim.utils import simple_preprocess

# Global cache to prevent reloading the model on every click
_dv_model = None
_topic_vectors = None
_topic_words = None

def _load_resources(model_dir):
    """
    Load the Doc2Vec model and Topic Vectors from the specified directory.
    This runs once and caches the result.
    """
    global _dv_model, _topic_vectors, _topic_words

    try:
        if _dv_model is None:
            model_path = os.path.join(model_dir, "doc2vec_lite.model")
            if os.path.exists(model_path):
                print(f"Loading Doc2Vec model from {model_path}...")
                _dv_model = Doc2Vec.load(model_path)
            else:
                print(f"Error: Doc2Vec model not found at {model_path}")

        if _topic_vectors is None:
            vec_path = os.path.join(model_dir, "topic_vectors.npy")
            if os.path.exists(vec_path):
                print(f"Loading topic vectors from {vec_path}...")
                _topic_vectors = np.load(vec_path)

        # Optional: Load words if you want to verify topics later
        if _topic_words is None:
            words_path = os.path.join(model_dir, "topic_words.npy")
            if os.path.exists(words_path):
                _topic_words = np.load(words_path, allow_pickle=True)

    except Exception as e:
        print(f"Error loading resources: {e}")

def classify_file(model_dir, text):
    """
    Classify text using Cosine Similarity between the doc vector and topic centroids.

    Args:
        model_dir (str): Path to the directory containing model files.
        text (str): The document text to classify.

    Returns:
        dict: {"topic_number": int, "confidence": float}
    """
    try:
        # 1. Validate Input
        if not text or len(text.strip()) < 10:
            return {"topic_number": -1, "confidence": 0.0}

        # 2. Load Resources (if not already loaded)
        _load_resources(model_dir)

        if _dv_model is None or _topic_vectors is None:
            print("Model resources missing. Falling back to keywords.")
            return classify_with_keywords(text)

        # 3. Preprocess Text (Must match how the model was trained!)
        tokens = simple_preprocess(text)
        if not tokens:
            return {"topic_number": -1, "confidence": 0.0}

        # 4. Infer Vector
        # Generates a vector representation for the new text
        doc_vector = _dv_model.infer_vector(tokens)

        # 5. Calculate Cosine Similarity with all Topic Vectors
        # Similarity = (A . B) / (||A|| * ||B||)

        # Dot product
        scores = np.dot(_topic_vectors, doc_vector)

        # Magnitudes (Norms)
        topic_norms = np.linalg.norm(_topic_vectors, axis=1)
        doc_norm = np.linalg.norm(doc_vector)

        # Avoid division by zero
        if doc_norm == 0:
            return {"topic_number": -1, "confidence": 0.0}

        cosine_sims = scores / (topic_norms * doc_norm)

        # 6. Find Best Match
        best_topic_idx = int(np.argmax(cosine_sims))
        raw_score = float(cosine_sims[best_topic_idx])

        # Clamp score to 0.0 - 1.0 range for UI display
        confidence = max(0.0, min(raw_score, 1.0))

        return {
            "topic_number": best_topic_idx,
            "confidence": confidence
        }

    except Exception as e:
        print(f"Classification Error: {e}")
        return classify_with_keywords(text)

def classify_with_keywords(text):
    """Fallback: Simple keyword-based classification"""
    try:
        text_lower = text.lower()

        # 0: Finance, 1: Work, 2: Personal, 3: Research
        categories = {
            0: ["finance", "money", "budget", "invoice", "receipt", "bank"],
            1: ["work", "project", "meeting", "deadline", "client", "proposal"],
            2: ["personal", "diary", "family", "vacation", "grocery", "gym"],
            3: ["research", "paper", "study", "experiment", "analysis", "data"]
        }

        scores = {}
        for topic_num, keywords in categories.items():
            matches = sum(1 for kw in keywords if kw in text_lower)
            if matches > 0:
                scores[topic_num] = matches

        if not scores:
            return {"topic_number": -1, "confidence": 0.0}

        best_topic = max(scores.items(), key=lambda x: x[1])
        # Arbitrary confidence calc for keywords
        confidence = min(best_topic[1] * 0.2, 1.0)

        return {
            "topic_number": best_topic[0],
            "confidence": confidence
        }

    except Exception as e:
        print(f"Keyword classification error: {e}")
        return {"topic_number": -1, "confidence": 0.0}