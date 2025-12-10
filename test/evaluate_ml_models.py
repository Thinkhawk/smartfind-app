import sys
import os
import time
import json
import numpy as np
import re
from sklearn.metrics import accuracy_score, matthews_corrcoef, confusion_matrix
from sklearn.metrics.pairwise import cosine_similarity
from scipy import spatial

# --- SETUP PATHS ---
PROJECT_ROOT = os.getcwd()
PYTHON_SOURCE_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/python")
ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets/models")
TOPIC_MAP_PATH = os.path.join(PROJECT_ROOT, "assets/models/topic_map.json")

sys.path.append(PYTHON_SOURCE_DIR)

try:
    import classifier
    import search_engine
    import summarizer
    print("✅ Successfully imported app modules")
except ImportError as e:
    print("❌ Error importing modules. Run from project root.")
    raise e

# Initialize resources once
if not classifier.load_resources(ASSETS_DIR):
    print("❌ Failed to load model resources.")
    sys.exit(1)

def calc_similarity(vec1, vec2):
    if vec1 is None or vec2 is None: return 0.0
    return 1 - spatial.distance.cosine(vec1, vec2)

# ==========================================
# 1. CLASSIFIER EVALUATION
# ==========================================
def test_classifier():
    print("\n" + "="*60)
    print("TESTING MODEL 1: DOCUMENT CLASSIFIER")
    print("="*60)

    try:
        with open(TOPIC_MAP_PATH, 'r') as f:
            topic_map = json.load(f)
    except Exception as e:
        print(f"❌ Could not load topic_map.json: {e}")
        return

    test_data = [
        ("invoice services rendered total dollars bank transfer", "Finance"),
        ("quarterly earnings report revenue profit growth", "Finance"),
        ("recruitment candidate interview salary resume job", "Personal"),
        ("grocery list milk eggs bread butter snack food", "Personal"),
        ("software hardware server client network protocol", "Programming"),
        ("contract agreement party lawyer attorney law court", "Legal"),
        ("ticket boarding pass flight airline airport", "Travel"),
        ("homework assignment semester grade syllabus", "Education"),
    ]

    true_categories = [t[1] for t in test_data]
    pred_categories = []
    inference_times = []

    for text, expected in test_data:
        start = time.time()
        result = classifier.classify_file(ASSETS_DIR, text)
        end = time.time()

        topic_id = str(result['topic_number'])
        confidence = result['confidence']
        predicted_name = topic_map.get(topic_id, "General")

        if confidence < 0.2:
            predicted_name = "General (Low Conf)"

        pred_categories.append(predicted_name)
        inference_times.append((end - start) * 1000)

        status = "✅" if predicted_name == expected else "❌"
        print(f"{status} Pred: {predicted_name:<15} | Exp: {expected}")

    # --- METRICS ---
    accuracy = accuracy_score(true_categories, pred_categories)
    mcc = matthews_corrcoef(true_categories, pred_categories)

    print("-" * 60)
    print(f"RESULTS:")
    print(f"Accuracy:      {accuracy:.2%}")
    print(f"MCC Score:     {mcc:.2f} (1.0 is perfect)")
    print(f"Avg Latency:   {np.mean(inference_times):.2f} ms")

    # --- RESTORED: Confusion Matrix ---
    print("\nConfusion Matrix:")
    unique_labels = sorted(list(set(true_categories + pred_categories)))
    cm = confusion_matrix(true_categories, pred_categories, labels=unique_labels)
    print(f"Labels: {unique_labels}")
    print(cm)
    print("-" * 60)

# ==========================================
# 2. SEARCH ENGINE EVALUATION
# ==========================================
try:
    from evaluate_search_real import test_search_real_data
except ImportError:
    def test_search_real_data(): print("⚠️ evaluate_search_real.py not found.")

# ==========================================
# 3. SUMMARIZER EVALUATION
# ==========================================
def test_summarizer():
    print("\n" + "="*60)
    print("TESTING MODEL 3: SUMMARIZER")
    print("="*60)

    long_text = """
    Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by animals including humans. 
    Leading AI textbooks define the field as the study of "intelligent agents": any device that perceives its environment and takes actions that maximize its chance of successfully achieving its goals. 
    Colloquially, the term "artificial intelligence" is often used to describe machines (or computers) that mimic "cognitive" functions that humans associate with the human mind, such as "learning" and "problem solving".
    As machines become increasingly capable, tasks considered to require "intelligence" are often removed from the definition of AI, a phenomenon known as the AI effect. 
    """

    start = time.time()
    result = summarizer.summarize_file(long_text, max_sentences=2)
    end = time.time()

    summary = result['summary']
    compression_ratio = 1 - (len(summary) / len(long_text))
    latency = (end - start) * 1000

    # Semantic Similarity (Replaces Coverage)
    tokens_orig = classifier.simple_preprocess(long_text)
    tokens_sum = classifier.simple_preprocess(summary)
    vec_orig = classifier.infer_vector_manual(tokens_orig)
    vec_sum = classifier.infer_vector_manual(tokens_sum)

    semantic_sim = calc_similarity(vec_orig, vec_sum)

    print(f"Original: {len(long_text)} chars -> Summary: {len(summary)} chars")
    print("-" * 60)
    print(f"RESULTS:")
    print(f"Compression:   {compression_ratio:.2%}")
    print(f"Latency:       {latency:.2f} ms")
    print(f"Similarity:    {semantic_sim:.2f} (Using model vectors)")
    print(f"Output: \"{summary.strip()}\"")

# ==========================================
# 4. RECOMMENDATION SYSTEM EVALUATION
# ==========================================
def test_recommendation_system():
    print("\n" + "="*60)
    print("TESTING MODEL 4: RECOMMENDATION ENGINE")
    print("="*60)

    files = [
        ("space1.txt", "The sun is a star in the center of the solar system", "Science"),
        ("space2.txt", "Planets orbit around the sun due to gravity", "Science"),
        ("space3.txt", "NASA launches rockets to explore the universe", "Science"),
        ("money1.txt", "The stock market crashed due to inflation rates", "Finance"),
        ("money2.txt", "Banks offer loans and savings accounts for money", "Finance"),
        ("food1.txt",  "Recipe for chocolate cake with sugar and flour", "Personal"),
    ]

    file_vectors = []
    file_metadata = []

    for name, text, cat in files:
        tokens = classifier.simple_preprocess(text)
        vec = classifier.infer_vector_manual(tokens)
        if vec is not None:
            file_vectors.append(vec)
            file_metadata.append({'name': name, 'category': cat})

    file_vectors = np.array(file_vectors)
    k = 2
    total_precision = 0
    total_diversity = 0

    print(f"{'Target':<12} | {'Recommendations':<30} | {'Precision'}")
    print("-" * 60)

    for i, target_vec in enumerate(file_vectors):
        sims = cosine_similarity([target_vec], file_vectors)[0]
        sims[i] = -1
        top_indices = np.argsort(sims)[::-1][:k]

        rec_names = []
        rec_vectors = []
        relevant_hits = 0

        for idx in top_indices:
            rec = file_metadata[idx]
            rec_names.append(rec['name'])
            rec_vectors.append(file_vectors[idx])
            if rec['category'] == file_metadata[i]['category']:
                relevant_hits += 1

        precision = relevant_hits / k
        total_precision += precision

        diversity = 0
        if len(rec_vectors) > 1:
            intra_sim = cosine_similarity(rec_vectors)
            avg_sim = np.mean(intra_sim[np.triu_indices(len(rec_vectors), k=1)])
            diversity = 1 - avg_sim
        else:
            diversity = 1.0

        total_diversity += diversity
        print(f"{file_metadata[i]['name']:<12} | {str(rec_names):<30} | {precision:.0%}")

    avg_precision = total_precision / len(files)
    avg_diversity = total_diversity / len(files)

    print("-" * 60)
    print(f"RESULTS:")
    print(f"Precision@2:   {avg_precision:.2%}")
    print(f"Diversity:     {avg_diversity:.2f}")

if __name__ == "__main__":
    test_classifier()
    test_search_real_data()
    test_summarizer()
    test_recommendation_system()