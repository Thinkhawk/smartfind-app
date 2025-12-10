import os
import json
import numpy as np
from gensim.models.doc2vec import Doc2Vec

# Paths
INPUT_MODEL = "android/app/src/main/assets/models/doc2vec_lite.model"
OUTPUT_DIR = "assets/models"

def main():
    print(f"Loading {INPUT_MODEL}...")
    try:
        # Load the fragile model
        model = Doc2Vec.load(INPUT_MODEL)

        # 1. Export Vocabulary (Map word -> index)
        # This acts as the dictionary
        print("Exporting Vocabulary...")
        vocab = {word: i for i, word in enumerate(model.wv.index_to_key)}
        with open(os.path.join(OUTPUT_DIR, "vocab.json"), "w", encoding="utf-8") as f:
            json.dump(vocab, f)

        # 2. Export Word Vectors (The actual math)
        # This acts as the brain weights
        print("Exporting Word Vectors...")
        # Save as standard Float32 numpy array (Universal format)
        np.save(os.path.join(OUTPUT_DIR, "word_vectors.npy"), model.wv.vectors.astype(np.float32))

        # 3. Ensure Topic Vectors exist
        # (You likely already have this, but ensuring it's Float32 is safer)
        if os.path.exists(os.path.join(OUTPUT_DIR, "topic_vectors.npy")):
            print("Re-saving Topic Vectors as Float32 for safety...")
            topics = np.load(os.path.join(OUTPUT_DIR, "topic_vectors.npy"))
            np.save(os.path.join(OUTPUT_DIR, "topic_vectors.npy"), topics.astype(np.float32))

        print("\n✅ SUCCESS!")
        print("Created 'vocab.json' and 'word_vectors.npy'")
        print("ACTION: Copy these new files to your Android assets folder.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()