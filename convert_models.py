import numpy as np
import json
import os

# Paths to your existing assets
ASSETS_DIR = "assets/models"
files = {
    "word_vectors.npy": "word_vectors.json",
    "topic_vectors.npy": "topic_vectors.json"
}

print("Converting models to JSON for iOS...")

for npy_file, json_file in files.items():
    src = os.path.join(ASSETS_DIR, npy_file)
    dst = os.path.join(ASSETS_DIR, json_file)

    if os.path.exists(src):
        print(f"Converting {npy_file}...")
        # Load numpy array
        arr = np.load(src)
        # Convert to standard list
        arr_list = arr.tolist()

        # Save as JSON
        with open(dst, "w") as f:
            json.dump(arr_list, f)
        print(f"Saved {json_file}")
    else:
        print(f"Skipping {npy_file} (Not found)")

print("Done! Copy the new .json files to 'ios/Runner/Assets.xcassets' or drag them into Xcode.")