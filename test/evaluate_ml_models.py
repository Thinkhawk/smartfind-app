import sys
import os
import time
import json
import shutil
import tempfile
import numpy as np
import re
from collections import Counter
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, matthews_corrcoef
from sklearn.metrics.pairwise import cosine_similarity
from scipy import spatial
from gensim.models.doc2vec import Doc2Vec

# --- SETUP PATHS ---
PROJECT_ROOT = os.getcwd()
PYTHON_SOURCE_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/python")
ASSETS_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/assets/models")
TOPIC_MAP_PATH = os.path.join(PROJECT_ROOT, "assets/topic_map.json")

sys.path.append(PYTHON_SOURCE_DIR)

try:
    import classifier
    import search_engine
    import summarizer
    import recommender
    print("✅ Successfully imported app modules")
except ImportError as e:
    print("❌ Error importing modules. Run from project root.")
    raise e

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
        print(f"✅ Loaded Topic Map ({len(topic_map)} entries)")
    except Exception as e:
        print(f"❌ Could not load topic_map.json: {e}")
        return

    test_data = [
        ("invoice services rendered total dollars bank transfer", "Finance"),
        ("quarterly earnings report revenue profit growth", "Finance"),
        ("corporate strategy acquisition market share industry", "Business"),
        ("recruitment candidate interview salary resume job", "Jobs"),
        ("grocery list milk eggs bread butter snack food", "Food"),
        ("neural network deep learning software data analytics", "Internet"),
        ("study climate change biodiversity species forest", "Environment"),
    ]

    true_categories = [t[1] for t in test_data]
    pred_categories = []
    inference_times = []

    print(f"Running inference on {len(test_data)} samples...")

    for text, expected in test_data:
        start = time.time()
        result = classifier.classify_file(ASSETS_DIR, text)
        end = time.time()

        topic_id = str(result['topic_number'])
        confidence = result['confidence']
        predicted_name = topic_map.get(topic_id, "Unknown")

        if predicted_name == "Unknown":
            predicted_name = topic_map.get("default", "General")

        if confidence < 0.2:
            predicted_name = "General (Low Conf)"

        pred_categories.append(predicted_name)
        inference_times.append((end - start) * 1000)

        status = "✅" if predicted_name == expected else "❌"
        print(f"{status} Text: '{text[:20]}...' -> Pred: {predicted_name} (Exp: {expected})")

    accuracy = accuracy_score(true_categories, pred_categories)
    mcc = matthews_corrcoef(true_categories, pred_categories)

    print("-" * 60)
    print(f"RESULTS:")
    print(f"Accuracy:      {accuracy:.2%}")
    print(f"MCC Score:     {mcc:.2f} (1.0 is perfect)")
    print(f"Avg Latency:   {np.mean(inference_times):.2f} ms")

    print("\nConfusion Matrix (Rows=True, Cols=Pred):")
    unique_labels = sorted(list(set(true_categories + pred_categories)))
    cm = confusion_matrix(true_categories, pred_categories, labels=unique_labels)
    print(f"Labels: {unique_labels}")
    print(cm)
    print("-" * 60)

# ==========================================
# 2. SEARCH ENGINE EVALUATION
# ==========================================
from evaluate_search_real import test_search_real_data as test_search_engine

# ==========================================
# 3. SUMMARIZER EVALUATION
# ==========================================
def calculate_overlap(text1, text2):
    def tokenize(t): return set(re.findall(r'\w+', t.lower()))
    tokens1 = tokenize(text1)
    tokens2 = tokenize(text2)
    if not tokens1: return 0.0
    intersection = tokens1.intersection(tokens2)
    return len(intersection) / len(tokens1)

def test_summarizer():
    print("\n" + "="*60)
    print("TESTING MODEL 3: SUMMARIZER")
    print("="*60)

    long_text = """
    Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by animals including humans. 
    Leading AI textbooks define the field as the study of "intelligent agents": any device that perceives its environment and takes actions that maximize its chance of successfully achieving its goals. 
    Colloquially, the term "artificial intelligence" is often used to describe machines (or computers) that mimic "cognitive" functions that humans associate with the human mind, such as "learning" and "problem solving".
    As machines become increasingly capable, tasks considered to require "intelligence" are often removed from the definition of AI, a phenomenon known as the AI effect. 
    A quip in Tesler's Theorem says "AI is whatever hasn't been done yet." 
    For instance, optical character recognition is frequently excluded from things considered to be AI, having become a routine technology.
    """

    key_terms = "intelligence machines AI agents cognitive learning problem solving"

    start = time.time()
    result = summarizer.summarize_file(long_text, max_sentences=2)
    end = time.time()

    summary = result['summary']
    compression_ratio = 1 - (len(summary) / len(long_text))
    latency = (end - start) * 1000

    coverage = calculate_overlap(key_terms, summary)

    try:
        model = Doc2Vec.load(os.path.join(ASSETS_DIR, "doc2vec_lite.model"))
        vec_orig = model.infer_vector(long_text.split())
        vec_sum = model.infer_vector(summary.split())
        semantic_sim = 1 - spatial.distance.cosine(vec_orig, vec_sum)
    except Exception as e:
        semantic_sim = 0.0

    print(f"Original: {len(long_text)} chars -> Summary: {len(summary)} chars")
    print("-" * 60)
    print(f"RESULTS:")
    print(f"Compression Ratio:   {compression_ratio:.2%}")
    print(f"Latency:             {latency:.2f} ms")
    print(f"Semantic Similarity: {semantic_sim:.2f} (Meaning preservation 0-1)")
    print(f"Output: \"{summary.strip()}\"")

# ==========================================
# 4. RECOMMENDATION SYSTEM EVALUATION
# ==========================================
def test_recommendation_system():
    print("\n" + "="*60)
    print("TESTING MODEL 4: RECOMMENDATION ENGINE")
    print("="*60)

    # 1. Setup Mock User Data (Content Clusters)
    files = [
        # Cluster A: Space
        ("space_1.txt", "The sun is a star in the center of the solar system", "Space"),
        ("space_2.txt", "Planets orbit around the sun due to gravity", "Space"),
        ("space_3.txt", "NASA launches rockets to explore the universe", "Space"),

        # Cluster B: Finance
        ("finance_1.txt", "The stock market crashed due to inflation rates", "Finance"),
        ("finance_2.txt", "Banks offer loans and savings accounts for money", "Finance"),
        ("finance_3.txt", "Investment strategy for long term capital gains", "Finance"),

        # Cluster C: Food
        ("cook_1.txt", "Recipe for chocolate cake with sugar and flour", "Food"),
        ("cook_2.txt", "How to bake bread using yeast and water", "Food"),
        ("cook_3.txt", "Grilling vegetables with olive oil and salt", "Food"),
    ]

    try:
        # Load the Brain
        model = Doc2Vec.load(os.path.join(ASSETS_DIR, "doc2vec_lite.model"))

        # 2. Generate Vectors
        file_vectors = []
        file_metadata = []

        for name, text, category in files:
            vector = model.infer_vector(text.lower().split())
            file_vectors.append(vector)
            file_metadata.append({'name': name, 'category': category})

        file_vectors = np.array(file_vectors)

        # 3. Evaluate Recommendations
        k = 2 # Recommend Top 2 files (since we only have 3 per cluster)
        total_precision = 0
        total_diversity = 0

        print(f"{'Target File':<15} | {'Recommendations':<35} | {'Precision'}")
        print("-" * 75)

        for i, target_vec in enumerate(file_vectors):
            target_meta = file_metadata[i]

            # Similarity of this file vs ALL others
            sims = cosine_similarity([target_vec], file_vectors)[0]

            # Get top indices (skip index 0 which is self)
            top_indices = sims.argsort()[::-1][1:k+1]

            # Metrics
            relevant_hits = 0
            rec_vectors = []
            rec_names = []

            for idx in top_indices:
                rec_item = file_metadata[idx]
                rec_vectors.append(file_vectors[idx])
                rec_names.append(rec_item['name'])

                # RELEVANCE: Does category match?
                if rec_item['category'] == target_meta['category']:
                    relevant_hits += 1

            precision = relevant_hits / k
            total_precision += precision

            # DIVERSITY: (1 - Avg Similarity between recommendations)
            if len(rec_vectors) > 1:
                intra_sim = cosine_similarity(rec_vectors)
                avg_sim = np.mean(intra_sim[np.triu_indices(len(rec_vectors), k=1)])
                diversity = 1 - avg_sim
            else:
                diversity = 0 # N/A

            total_diversity += diversity

            print(f"{target_meta['name']:<15} | {str(rec_names):<35} | {precision:.0%}")

        # 4. Aggregate Results
        avg_precision = total_precision / len(files)
        avg_diversity = total_diversity / len(files)

        print("-" * 75)
        print(f"RESULTS:")
        print(f"Mean Precision@{k}:   {avg_precision:.2%}")
        print(f"Diversity Score:     {avg_diversity:.2f} (0=Duplicates, 1=Unique)")

        if avg_precision > 0.7:
            print("✅ Recommendation Logic Verified")
        else:
            print("⚠️ Recommendations may be noisy")

    except Exception as e:
        print(f"❌ Recommendation Test Failed: {e}")

if __name__ == "__main__":
    test_classifier()
    test_search_engine()
    test_summarizer()
    test_recommendation_system()