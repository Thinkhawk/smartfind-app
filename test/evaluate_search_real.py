import sys
import os
import json
import shutil
import tempfile
from sklearn.datasets import fetch_20newsgroups

# --- SETUP PATHS ---
PROJECT_ROOT = os.getcwd()
PYTHON_SOURCE_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/python")
ASSETS_SRC = os.path.join(PROJECT_ROOT, "assets/models")

sys.path.append(PYTHON_SOURCE_DIR)

try:
    import search_engine
    print("✅ Successfully imported search_engine")
except ImportError as e:
    print("❌ Error importing search_engine. Run from project root.")
    raise e

def setup_test_environment(test_dir):
    """Copies model assets to the temp directory so search_engine can find them"""
    models_dir = os.path.join(test_dir, "models")
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)

    # Copy essential files
    for file in ["vocab.json", "word_vectors.npy", "topic_vectors.npy"]:
        src = os.path.join(ASSETS_SRC, file)
        dst = os.path.join(models_dir, file)
        if os.path.exists(src):
            shutil.copy(src, dst)
        else:
            print(f"⚠️ Warning: {file} not found in assets/models")

def test_search_real_data():
    print("\n" + "="*50)
    print("TESTING SEARCH ENGINE WITH REAL DATA")
    print("="*50)

    # 1. Fetch Data
    categories = ['sci.space', 'rec.sport.hockey', 'sci.med']
    print("Downloading test data...")
    dataset = fetch_20newsgroups(subset='test', categories=categories,
                                 remove=('headers', 'footers', 'quotes'))

    # 2. Build Documents
    documents = {}
    doc_categories = {}

    print(f"Building index with {len(dataset.data)} documents...")
    for i, text in enumerate(dataset.data):
        if len(text) < 50: continue
        category = dataset.target_names[dataset.target[i]]
        # Create a fake path
        filename = f"/storage/emulated/0/Download/{category}_{i}.txt"
        documents[filename] = text
        doc_categories[filename] = category

    # 3. Setup Temp Dir
    test_dir = tempfile.mkdtemp()
    setup_test_environment(test_dir)

    try:
        # 4. Train Index
        search_engine.train_local_index(test_dir, json.dumps(documents))
        print(f"✅ Indexed documents successfully.")

        # 5. Run Queries
        queries = [
            ("orbit moon", "sci.space"),
            ("nasa launch", "sci.space"),
            ("puck goal", "rec.sport.hockey"),
            ("doctor patient", "sci.med"),
        ]

        print("\nRunning Queries...")
        print("-" * 65)
        print(f"{'Query':<15} | {'Top Result Category':<25} | {'Rank'}")
        print("-" * 65)

        hits = 0
        mrr_sum = 0.0  # Initialize MRR sum

        for query, expected_category in queries:
            # Pass test_dir as the 'app_files_dir'
            results = search_engine.search_documents(test_dir, query)['results']

            found_cat = "Not Found"
            rank = 0  # 0 means not found

            if results:
                # Check top result
                top_path = results[0]
                found_cat = doc_categories.get(top_path, "Unknown")

                # Check if we found a relevant doc in top results
                for i, path in enumerate(results):
                    if expected_category in path:
                        rank = i + 1
                        hits += 1
                        break

            # Calculate Reciprocal Rank for this query
            if rank > 0:
                reciprocal_rank = 1.0 / rank
                print(f"'{query}'".ljust(15) + f" | {found_cat:<25} | {rank}")
            else:
                reciprocal_rank = 0.0
                print(f"'{query}'".ljust(15) + f" | {found_cat:<25} | Not Found")

            mrr_sum += reciprocal_rank

        # Final Metrics
        mrr = mrr_sum / len(queries)
        print("-" * 65)
        print(f"Success Rate: {hits}/{len(queries)}")
        print(f"MRR Score:    {mrr:.2f} (Higher is better, max 1.0)")

    finally:
        shutil.rmtree(test_dir)