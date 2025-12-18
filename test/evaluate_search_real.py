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

if PYTHON_SOURCE_DIR not in sys.path:
    sys.path.append(PYTHON_SOURCE_DIR)

import search_engine

def setup_test_environment(test_dir):
    """Copies model assets to the temp directory so search_engine can find them"""
    models_dir = os.path.join(test_dir, "models")
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)

    for file in ["vocab.json", "word_vectors.npy", "topic_vectors.npy"]:
        src = os.path.join(ASSETS_SRC, file)
        dst = os.path.join(models_dir, file)
        if os.path.exists(src):
            shutil.copy(src, dst)

def test_search_real_data():
    # 1. Fetch Data (6 categories for higher stress)
    categories = ['sci.space', 'rec.sport.hockey', 'sci.med', 'comp.graphics', 'sci.electronics', 'rec.autos']
    dataset = fetch_20newsgroups(subset='test', categories=categories, remove=('headers', 'footers', 'quotes'))

    documents = {}
    doc_categories = {}
    for i, text in enumerate(dataset.data):
        if len(text) < 50: continue
        category = dataset.target_names[dataset.target[i]]
        path = f"/storage/{category}_{i}.txt"
        documents[path] = text
        doc_categories[path] = category

    test_dir = tempfile.mkdtemp()
    setup_test_environment(test_dir)

    try:
        # 2. Train Index
        search_engine.train_local_index(test_dir, json.dumps(documents))

        # 3. Run Queries
        queries = [
            ("orbit moon", "sci.space"), ("nasa launch", "sci.space"),
            ("puck goal", "rec.sport.hockey"), ("doctor patient", "sci.med"),
            ("3d rendering", "comp.graphics"), ("circuit board", "sci.electronics"),
            ("engine transmission", "rec.autos"), ("voltage signal", "sci.electronics")
        ]

        hits, mrr_sum = 0, 0.0
        for query, expected_cat in queries:
            results = search_engine.search_documents(test_dir, query)['results']
            if results:
                for i, path in enumerate(results):
                    if expected_cat in path:
                        hits += 1
                        mrr_sum += (1.0 / (i + 1))
                        break

        # RETURN metrics instead of just printing
        return {
            "docs": len(documents),
            "success": f"{hits}/{len(queries)}",
            "mrr": f"{(mrr_sum / len(queries)):.2f}"
        }
    finally:
        shutil.rmtree(test_dir)