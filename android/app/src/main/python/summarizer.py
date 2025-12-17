import re
import numpy as np
import networkx as nx
from gensim.utils import simple_preprocess


def cosine_similarity(v1, v2):
    dot_product = np.dot(v1, v2)
    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)
    if norm_v1 == 0 or norm_v2 == 0:
        return 0.0
    return dot_product / (norm_v1 * norm_v2)


def sentence_similarity(sent1, sent2, stopwords=None):
    if stopwords is None:
        stopwords = set()

    words1 = [w.lower() for w in sent1 if w.lower() not in stopwords]
    words2 = [w.lower() for w in sent2 if w.lower() not in stopwords]

    all_words = list(set(words1 + words2))

    vector1 = [0] * len(all_words)
    vector2 = [0] * len(all_words)

    for w in words1:
        vector1[all_words.index(w)] += 1

    for w in words2:
        vector2[all_words.index(w)] += 1

    return 1 - cosine_similarity(vector1, vector2)


def summarize_file(text, max_sentences=5):
    try:
        if not text or len(text.strip()) < 50:
            return {"summary": text[:500]}

        sentences = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?|\!)\s', text)
        sentences = [s.strip() for s in sentences if len(s.split()) > 4]  # Filter tiny sentences

        if len(sentences) <= max_sentences:
            return {"summary": " ".join(sentences)}

        sentence_tokens = [simple_preprocess(s) for s in sentences]

        sim_mat = np.zeros([len(sentences), len(sentences)])

        stopwords = {
            'the', 'and', 'of', 'to', 'a', 'in', 'is', 'that', 'for', 'it', 'on',
            'with', 'as', 'are', 'was', 'this', 'by', 'be', 'at', 'or', 'from',
            'an', 'not', 'but', 'can', 'if', 'we', 'has', 'have', 'which', 'their',
            'will', 'its', 'about', 'would', 'there', 'so', 'what', 'who', 'when',
            'they', 'he', 'she', 'his', 'her', 'been', 'had', 'were', 'one', 'all',
            'you', 'your', 'my', 'our', 'me', 'us', 'him', 'them'
        }

        for i in range(len(sentences)):
            for j in range(len(sentences)):
                if i != j:
                    set_i = set(w for w in sentence_tokens[i] if w not in stopwords)
                    set_j = set(w for w in sentence_tokens[j] if w not in stopwords)

                    if not set_i or not set_j:
                        sim_mat[i][j] = 0.0
                        continue

                    intersection = len(set_i.intersection(set_j))
                    log_len = np.log(len(set_i)) + np.log(len(set_j))

                    if log_len == 0:
                        sim_mat[i][j] = 0.0
                    else:
                        sim_mat[i][j] = intersection / log_len

        nx_graph = nx.from_numpy_array(sim_mat)

        scores = nx.pagerank(nx_graph)

        ranked_sentences = sorted(((scores[i], s) for i, s in enumerate(sentences)), reverse=True)

        # Get top N
        top_sentences_list = [s[1] for s in ranked_sentences[:max_sentences]]

        final_summary_sentences = []
        for sent in sentences:
            if sent in top_sentences_list:
                final_summary_sentences.append(sent)

        return {"summary": " ".join(final_summary_sentences)}

    except Exception as e:
        print(f"Summarization Error: {e}")
        import traceback
        traceback.print_exc()
        return {"summary": text[:500] + "..."}
