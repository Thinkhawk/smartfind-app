"""
Time-Aware Recommendation Engine
Learns user habits based on Day of Week and Hour of Day.
"""
import os
import csv
import json
import pickle
from datetime import datetime
from collections import defaultdict, Counter

# Global cache
_model = None

# Model File Path
def _get_model_path(data_dir):
    models_dir = os.path.join(data_dir, "models")
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)
    return os.path.join(models_dir, "recommender_model.pkl")

def _load_model(data_dir):
    """Load the frequency model from disk"""
    global _model
    if _model is None:
        path = _get_model_path(data_dir)
        if os.path.exists(path):
            try:
                with open(path, 'rb') as f:
                    _model = pickle.load(f)
            except Exception as e:
                print(f"DEBUG: Error loading recommender: {e}")
                _model = defaultdict(Counter)
        else:
            _model = defaultdict(Counter)
    return _model

def train_recommender(data_dir, log_path):
    """
    1. Read access_log.csv
    2. Update internal model (Day+Hour -> File Count)
    3. Clear access_log.csv (Incremental Learning)
    """
    global _model
    print("DEBUG: Training recommender...")

    try:
        if not os.path.exists(log_path):
            print("DEBUG: No access log found.")
            return {"status": "no_log"}

        # 1. Load existing model state
        model = _load_model(data_dir)

        # 2. Read and process new logs
        new_entries = 0
        with open(log_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    path = row.get('file_path')
                    timestamp_str = row.get('access_timestamp')

                    if not path or not timestamp_str: continue

                    # Parse Time
                    # Format: 2023-10-25T14:30:00.000
                    dt = datetime.fromisoformat(timestamp_str)

                    # Create Context Keys
                    # We track 2 contexts:
                    # A. Day of Week (0=Mon, 6=Sun)
                    # B. Time Block (Morning, Afternoon, Evening, Night)
                    weekday = dt.weekday()
                    hour = dt.hour

                    # Simplify hour into 4-hour blocks to group similar times
                    # (e.g., 9:00 AM and 10:30 AM are "Morning")
                    time_block = hour // 4

                    # Key: "Mon-Block2" (e.g., Monday Morning)
                    context_key = f"{weekday}-{time_block}"

                    # Update Frequency
                    model[context_key][path] += 1

                    # Also update a global "Recent" context for fallback
                    model["global"][path] += 1

                    new_entries += 1
                except Exception as row_e:
                    print(f"DEBUG: Skipped bad log row: {row_e}")

        if new_entries == 0:
            return {"status": "no_new_data"}

        # 3. Save updated model
        with open(_get_model_path(data_dir), 'wb') as f:
            pickle.dump(model, f)

        # 4. Clear the CSV (Reset buffer)
        # We re-write just the header
        with open(log_path, 'w', encoding='utf-8') as f:
            f.write('file_path,file_name,file_type,access_timestamp\n')

        print(f"DEBUG: Recommender trained on {new_entries} new events. Log cleared.")
        return {"status": "success", "count": new_entries}

    except Exception as e:
        print(f"DEBUG: Recommender training failed: {e}")
        return {"status": "error", "message": str(e)}

def get_recommendations(data_dir, month, weekday, hour):
    """
    Get top 5 files for the current time context.
    """
    try:
        model = _load_model(data_dir)
        if not model:
            return {"recommendations": []}

        recommendations = Counter()

        # 1. Current Context (e.g., "Monday Morning")
        time_block = hour // 4
        context_key = f"{weekday}-{time_block}"

        if context_key in model:
            # Give high weight to current context matches
            for path, count in model[context_key].items():
                recommendations[path] += count * 3

        # 2. Adjacent Context (e.g., if it's 8:59 AM, check 9:00 AM block too)
        # (Simplified: just check global popularity as fallback)
        if "global" in model:
            for path, count in model["global"].items():
                recommendations[path] += count * 1  # Lower weight

        # 3. Sort and Return Top 5
        # [('path1', score), ('path2', score)]
        top_files = recommendations.most_common(5)

        # Return just the paths
        result_paths = [path for path, score in top_files]

        print(f"DEBUG: Recommendations for {context_key}: {result_paths}")
        return {"recommendations": result_paths}

    except Exception as e:
        print(f"DEBUG: Prediction error: {e}")
        return {"recommendations": []}