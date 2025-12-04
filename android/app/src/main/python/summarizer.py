"""
Frequency-Based Summarizer
Implements the extractive technique described in "Extractive Automatic Text Summarization"
(Jugran et al.), adapted for pure Python to run efficiently on Android.
"""
import re
from collections import Counter
import heapq

def summarize_file(text, max_sentences=3):
    """
    Summarize text by scoring sentences based on word frequency.
    1. Calculate word frequency (Term Frequency)
    2. Score sentences based on the sum of their word frequencies
    3. Select top N sentences
    """
    try:
        # Basic validation
        if not text or len(text.strip()) < 50:
            return {"summary": text[:200]}

        # --- STEP 1: PREPROCESSING & WORD SCORING ---

        # Normalize text to lowercase
        text_lower = text.lower()

        # Remove special characters for word counting (keep alphanumeric + spaces)
        clean_text = re.sub(r'[^\w\s]', '', text_lower)
        words = clean_text.split()

        # Calculate Word Frequency
        # Stopwords list (Manual list to avoid heavy NLTK dependency)
        stopwords = {
            'the', 'and', 'of', 'to', 'a', 'in', 'is', 'that', 'for', 'it', 'on',
            'with', 'as', 'are', 'was', 'this', 'by', 'be', 'at', 'or', 'from',
            'an', 'not', 'but', 'can', 'if', 'we', 'has', 'have', 'which', 'their',
            'will', 'its', 'about', 'would', 'there', 'so', 'what', 'who', 'when',
            'they', 'he', 'she', 'his', 'her', 'been', 'had', 'were', 'one', 'all'
        }

        filtered_words = [w for w in words if w not in stopwords]

        if not filtered_words:
            return {"summary": text[:200]}

        word_frequencies = Counter(filtered_words)

        # Normalize frequencies (dividing by max freq)
        # This gives the most common word a score of 1.0
        max_freq = max(word_frequencies.values())
        for word in word_frequencies:
            word_frequencies[word] = word_frequencies[word] / max_freq

        # --- STEP 2: SENTENCE TOKENIZATION ---

        # Split text into sentences using Regex (splitting on . ! ? followed by space)
        # Lookbehind ensures we don't split on abbreviations like "Mr." or "U.S."
        sentences = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?|\!)\s', text)

        # Filter out very short "sentences" (often artifacts of splitting)
        sentences = [s.strip() for s in sentences if len(s.split()) > 4]

        if len(sentences) <= max_sentences:
            return {"summary": ' '.join(sentences)}

        # --- STEP 3: SENTENCE SCORING ---

        sentence_scores = {}

        for sent in sentences:
            # Tokenize sentence into words
            sent_words = re.sub(r'[^\w\s]', '', sent.lower()).split()

            # Calculate score
            score = 0
            word_count_in_sent = 0

            for word in sent_words:
                if word in word_frequencies:
                    score += word_frequencies[word]
                    word_count_in_sent += 1

            # Normalize by length to avoid favoring only long sentences
            if word_count_in_sent > 0:
                sentence_scores[sent] = score / len(sent_words)

        # --- STEP 4: SELECTION ---

        # Select top N sentences with highest scores
        top_sentences = heapq.nlargest(max_sentences, sentence_scores, key=sentence_scores.get)

        # Reorder selected sentences to match their original order in the text
        # This ensures the summary flows logically like a story
        final_summary_sentences = sorted(top_sentences, key=lambda s: sentences.index(s))

        return {"summary": ' '.join(final_summary_sentences)}

    except Exception as e:
        print(f"Summarization error: {e}")
        # Fallback to simple truncation if anything breaks
        return {"summary": text[:200] + "..."}