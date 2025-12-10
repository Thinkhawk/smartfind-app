import sys
import os
import json
import shutil
import tempfile
import numpy as np
from sklearn.datasets import fetch_20newsgroups

# --- SETUP PATHS ---
PROJECT_ROOT = os.getcwd()
PYTHON_SOURCE_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/python")
ASSETS_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/assets/models")

sys.path.append(PYTHON_SOURCE_DIR)

try:
    import search_engine
    print("✅ Successfully imported search_engine")
except ImportError as e:
    print("❌ Error importing search_engine. Run from project root.")
    raise e

def test_search_real_data():
    print("\n" + "="*50)
    print("TESTING SEARCH ENGINE WITH REAL DATA (20 Newsgroups)")
    print("="*50)

    # 1. Fetch Real Data (Space, Hockey, Medicine)
    # We grab 5 documents from each category to simulate a user's file system
    categories = ['sci.space', 'rec.sport.hockey', 'sci.med', 'comp.graphics']
    print("Downloading test data...")
    dataset = fetch_20newsgroups(subset='test', categories=categories,
                                 remove=('headers', 'footers', 'quotes'))

    # 2. Build Mock File System
    # Format: {"/docs/space_1.txt": "text...", "/docs/hockey_1.txt": "text..."}
    documents = {}
    doc_categories = {} # To check accuracy later

    print(f"Building index with {len(dataset.data)} real documents...")

    for i, text in enumerate(dataset.data):
        if len(text) < 50: continue # Skip tiny docs

        category = dataset.target_names[dataset.target[i]]
        filename = f"/docs/{category}_{i}.txt"

        documents[filename] = text
        doc_categories[filename] = category

    # 3. Train Search Index
    test_dir = tempfile.mkdtemp()
    try:
        search_engine.train_local_index(test_dir, json.dumps(documents))
        print(f"✅ Indexed {len(documents)} documents.")

        # 4. Run Queries
        # We search for keywords that definitely exist in these topics
        queries = [
            ("orbit", "sci.space"),
            ("nasa", "sci.space"),
            ("puck", "rec.sport.hockey"),
            ("goalie", "rec.sport.hockey"),
            ("patient", "sci.med"),
            ("disease", "sci.med"),
            ("pixel", "comp.graphics"),
            ("render", "comp.graphics")
        ]

        mrr_sum = 0
        hits = 0

        print("\nRunning Queries...")
        print("-" * 60)
        print(f"{'Query':<15} | {'Top Result Category':<25} | {'Rank'}")
        print("-" * 60)

        for query, expected_category in queries:
            results = search_engine.search_documents(test_dir, query)['results']

            # Find the rank of the FIRST result that matches the expected category
            rank = 0
            found_cat = "None"

            for i, path in enumerate(results):
                # Check if the result path contains the category name (e.g. /docs/sci.space_1.txt)
                if expected_category in path:
                    rank = i + 1
                    found_cat = expected_category
                    break
                elif i == 0:
                    # Capture the category of the top result for debugging
                    found_cat = doc_categories.get(path, "Unknown")

            if rank > 0:
                reciprocal_rank = 1.0 / rank
                hits += 1
                print(f"'{query}'".ljust(15) + f" | {found_cat:<25} | {rank}")
            else:
                reciprocal_rank = 0.0
                print(f"'{query}'".ljust(15) + f" | {found_cat:<25} | Not Found")

            mrr_sum += reciprocal_rank

        mrr = mrr_sum / len(queries)
        print("-" * 60)
        print(f"Total Queries: {len(queries)}")
        print(f"Successful Hits: {hits}")
        print(f"MRR (Mean Reciprocal Rank): {mrr:.2f}")

        if mrr > 0.7:
            print("\n✅ PASSED: Search Engine works on real English data.")
        else:
            print("\n⚠️ WARNING: Low performance. Check model compatibility.")

    finally:
        shutil.rmtree(test_dir)

# if __name__ == "__main__":
#     test_search_real_data()