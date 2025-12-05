"""
On-Device Search Engine: Semantic (Doc2Vec) + Optimized Disk-Based Keyword Search
Uses SQLite Contentless Tables to minimize storage usage.
"""
import os
import json
import sqlite3
import traceback
import numpy as np
from gensim.models.doc2vec import Doc2Vec, TaggedDocument
from gensim.utils import simple_preprocess

# Global cache
_model = None

print("DEBUG: search_engine module loaded successfully")

def _get_paths(data_dir):
    models_dir = os.path.join(data_dir, "models")
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)
    return {
        "model": os.path.join(models_dir, "local_search_model.d2v"),
        "db": os.path.join(models_dir, "search_index.db")
    }

def _get_db_connection(db_path):
    conn = sqlite3.connect(db_path)
    return conn

def _init_database(cursor):
    """
    Initialize database with the most efficient FTS engine available.
    """
    # 1. Create Mapping Table (ID -> Path)
    # We need this because Contentless FTS cannot return values, only Row IDs.
    cursor.execute("CREATE TABLE IF NOT EXISTS files_map (rowid INTEGER PRIMARY KEY, path TEXT)")

    # 2. Create Index Table (Content -> Row ID)
    # Try FTS5 Contentless (Best for space - does NOT store text)
    try:
        # content='' means "do not store the text body, just the index"
        cursor.execute("CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(content, content='')")
        print("DEBUG: Using FTS5 (Contentless) - Maximum Space Efficiency")
        return "fts5"
    except Exception as e:
        print(f"DEBUG: FTS5 not supported ({e}). Falling back to FTS4.")

    # Fallback: FTS4 (Standard, stores text)
    # FTS4 is available on almost all Android devices
    try:
        cursor.execute("CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts4(content)")
        print("DEBUG: Using FTS4 - Standard Compatibility")
        return "fts4"
    except Exception as e:
        print(f"DEBUG: CRITICAL DB ERROR: {e}")
        return None

def _load_resources(data_dir):
    """Load only the semantic model (SQLite is disk-based)"""
    global _model
    if _model is None:
        paths = _get_paths(data_dir)
        if os.path.exists(paths["model"]):
            try:
                _model = Doc2Vec.load(paths["model"])
                print("DEBUG: Semantic model loaded.")
            except Exception as e:
                print(f"DEBUG: Error loading semantic model: {e}")

def train_local_index(data_dir, json_data_str):
    """
    Train Semantic Model AND Build Optimized SQLite Index
    """
    global _model
    print("DEBUG: train_local_index called")

    try:
        py_file_map = json.loads(json_data_str)
        print(f"DEBUG: Processing {len(py_file_map)} docs...")

        if not py_file_map:
            return {"status": "empty"}

        paths = _get_paths(data_dir)

        # --- STEP 1: Build SQLite Index ---
        conn = _get_db_connection(paths["db"])
        cursor = conn.cursor()

        # Reset Tables
        cursor.execute("DROP TABLE IF EXISTS search_index")
        cursor.execute("DROP TABLE IF EXISTS files_map")

        table_type = _init_database(cursor)
        if not table_type:
            return {"status": "db_error"}

        tagged_data = []
        valid_count = 0

        for path, content in py_file_map.items():
            if not content: continue

            # 1. Insert Path into Map -> Get Row ID
            cursor.execute("INSERT INTO files_map (path) VALUES (?)", (path,))
            row_id = cursor.lastrowid

            # 2. Insert Content into Index using the SAME Row ID
            # This links the lightweight index to the filepath
            cursor.execute("INSERT INTO search_index (rowid, content) VALUES (?, ?)", (row_id, content))

            # 3. Prepare Semantic Data (Doc2Vec)
            tokens = simple_preprocess(str(content))
            if tokens:
                tagged_data.append(TaggedDocument(words=tokens, tags=[path]))
                valid_count += 1

        conn.commit()
        conn.close()
        print(f"DEBUG: SQLite Index built for {valid_count} docs.")

        if valid_count == 0:
            return {"status": "no_tokens"}

        # --- STEP 2: Train Semantic Model ---
        # Doc2Vec is efficient; it learns vector weights, doesn't store raw text.
        print("DEBUG: Training Doc2Vec...")
        model = Doc2Vec(vector_size=50, min_count=1, epochs=20)
        model.build_vocab(tagged_data)
        model.train(tagged_data, total_examples=model.corpus_count, epochs=model.epochs)

        model.save(paths["model"])
        _model = model

        print("DEBUG: Training complete.")
        return {"status": "success", "vocab_size": len(model.wv.key_to_index)}

    except Exception as e:
        print(f"DEBUG: TRAINING ERROR: {e}")
        traceback.print_exc()
        return {"status": "error", "message": str(e)}

def search_semantic(data_dir, query):
    """Doc2Vec Search"""
    try:
        _load_resources(data_dir)
        if _model is None or not query: return {"results": []}

        query_tokens = simple_preprocess(query)
        if not any(token in _model.wv.key_to_index for token in query_tokens):
            return {"results": []}

        query_vector = _model.infer_vector(query_tokens)
        sims = _model.dv.most_similar([query_vector], topn=10)

        results = [path for path, score in sims if score > 0.1]
        return {"results": results}
    except Exception as e:
        print(f"Semantic Search error: {e}")
        return {"results": []}

def search_keyword(data_dir, query):
    """
    Exact Match Search using Optimized SQLite
    """
    try:
        if not query: return {"results": []}

        paths = _get_paths(data_dir)
        if not os.path.exists(paths["db"]):
            return {"results": []}

        conn = _get_db_connection(paths["db"])
        cursor = conn.cursor()

        # 1. Sanitize Query
        clean_query = query.replace("'", "''")

        # 2. Search Index for Row IDs
        # Matches "query" OR "query*" (prefix match)
        sql_query = f"SELECT rowid FROM search_index WHERE content MATCH '{clean_query}*'"
        cursor.execute(sql_query)
        rows = cursor.fetchall()

        if not rows:
            conn.close()
            return {"results": []}

        # 3. Retrieve File Paths from Map
        row_ids = [str(r[0]) for r in rows]
        id_list = ",".join(row_ids)

        cursor.execute(f"SELECT path FROM files_map WHERE rowid IN ({id_list})")
        path_rows = cursor.fetchall()

        conn.close()

        results = [row[0] for row in path_rows]
        print(f"DEBUG: SQLite found {len(results)} matches for '{query}'")

        return {"results": results}

    except Exception as e:
        print(f"Keyword Search error: {e}")
        return {"results": []}