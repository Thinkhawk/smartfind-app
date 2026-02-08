import re
import numpy as np
import networkx as nx
from gensim.utils import simple_preprocess

# Robust set of stopwords to filter noise during similarity analysis
STOPWORDS = {
    'the', 'and', 'of', 'to', 'a', 'in', 'is', 'that', 'for', 'it', 'on',
    'with', 'as', 'are', 'was', 'this', 'by', 'be', 'at', 'or', 'from',
    'an', 'not', 'but', 'can', 'if', 'we', 'has', 'have', 'which', 'their',
    'will', 'its', 'about', 'would', 'there', 'so', 'what', 'who', 'when',
    'they', 'he', 'she', 'his', 'her', 'been', 'had', 'were', 'one', 'all',
    'you', 'your', 'my', 'our', 'me', 'us', 'him', 'them', 'page', 'pdf', 'file'
}

def summarize_file(text, max_sentences=3):
    """
    Main entry point called by the Android MethodChannel.
    Extracts the middle portion of a document and performs TextRank summarization.
    """
    try:
        # 1. Initial Length Check: Skip if text is extremely sparse
        if not text or len(text.strip()) < 100:
            return {"summary": "ERROR_TOO_SHORT"}

        # 2. Sentence Splitting
        # Uses regex to split on punctuation while ignoring acronyms (e.g., U.S.A.)
        raw_sentences = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?|\!)\s', text)

        # Filter: Only keep sentences with > 5 words to remove fragments and headers
        # This prevents the "of the and" issue by ignoring noise
        sentences = [s.strip() for s in raw_sentences if len(s.split()) > 5]

        # 3. Target the Middle Portion
        # This skips intro pages (Title, Index) and concluding noise (References)
        total_sents = len(sentences)
        if total_sents > 10:
            # Slice the document to keep the middle 70% (Skip 15% at each end)
            start_idx = int(total_sents * 0.15)
            end_idx = int(total_sents * 0.85)
            target_sentences = sentences[start_idx:end_idx]
        else:
            target_sentences = sentences

        # 4. Threshold Check: Ensure we have enough sentences to summarize meaningfully
        if len(target_sentences) <= max_sentences:
            return {"summary": "ERROR_TOO_SHORT"}

        # 5. Preprocessing for Similarity Graph
        # Extract meaningful tokens (excluding stopwords) for each sentence
        sentence_tokens = []
        for s in target_sentences:
            tokens = simple_preprocess(s)
            meaningful = set(w for w in tokens if w not in STOPWORDS)
            sentence_tokens.append(meaningful)

        num_sents = len(target_sentences)
        sim_mat = np.zeros([num_sents, num_sents])

        # 6. Build Similarity Matrix (The "Connections")
        for i in range(num_sents):
            for j in range(num_sents):
                if i != j:
                    set_i = sentence_tokens[i]
                    set_j = sentence_tokens[j]

                    if not set_i or not set_j:
                        continue

                    # Calculate overlap similarity normalized by sentence length log
                    intersection = len(set_i.intersection(set_j))
                    log_len = np.log(len(set_i)) + np.log(len(set_j))

                    if log_len > 0:
                        sim_mat[i][j] = intersection / log_len

        # 7. Run PageRank (TextRank Algorithm)
        nx_graph = nx.from_numpy_array(sim_mat)
        scores = nx.pagerank(nx_graph, max_iter=100)

        # 8. Rank and Select Top Sentences
        # Pair importance scores with original indices in the target list
        ranked_sentences = sorted(((scores[i], i) for i in range(num_sents)), reverse=True)

        # Extract indices of the top N sentences
        top_indices = [idx for score, idx in ranked_sentences[:max_sentences]]

        # Restore chronological order for logical readability
        top_indices.sort()

        final_summary_list = [target_sentences[i] for i in top_indices]

        return {"summary": " ".join(final_summary_list)}

    except Exception as e:
        # Debugging error handling
        print(f"Summarization Error in summarizer.py: {e}")
        import traceback
        traceback.print_exc()
        # Fallback: Return a simple snippet if the algorithm fails
        return {"summary": text[:300] + "..."}