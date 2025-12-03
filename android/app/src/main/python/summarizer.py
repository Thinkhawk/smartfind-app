"""
Simple text summarizer (pure Python)
"""

import re

def summarize_file(text, max_sentences=3):
    """Extract key sentences for summary"""
    try:
        if not text or len(text.strip()) < 50:
            return {"summary": text[:100]}

        # Split into sentences
        sentences = re.split(r'[.!?]+', text)
        sentences = [s.strip() for s in sentences if len(s.strip()) > 20]

        if len(sentences) <= max_sentences:
            summary = '. '.join(sentences) + '.'
            return {"summary": summary[:300]}

        # Score by position (beginning and end are usually important)
        scored = []
        for i, sent in enumerate(sentences):
            # Favor beginning and end
            position_score = 1.0 if i < 2 else (0.8 if i >= len(sentences) - 2 else 0.5)
            # Length bonus
            length_score = min(len(sent.split()) / 20.0, 1.0)

            score = (position_score * 0.6 + length_score * 0.4)
            scored.append((sent, score))

        # Get top sentences
        top = sorted(scored, key=lambda x: x[1], reverse=True)[:max_sentences]
        summary = '. '.join([s[0] for s in top]) + '.'

        return {"summary": summary[:300]}

    except Exception as e:
        print(f"Summarization error: {e}")
        return {"summary": text[:100]}
