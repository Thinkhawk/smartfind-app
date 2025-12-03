"""
Top2Vec-based classifier with fallback to keyword matching
"""
import os
import pickle


def classify_file(model_path, text):
    """Classify document using Top2Vec model, fallback to keywords"""
    try:
        # Validate input
        if not text or len(text.strip()) < 10:
            return {"topic_number": -1, "confidence": 0.0}

        # Try to load pickled Top2Vec model
        if os.path.exists(model_path):
            try:
                with open(model_path, 'rb') as f:
                    model = pickle.load(f)

                # Query topics for the text
                topic_data = model.query_topics(text, num_topics=1)

                if topic_data and len(topic_data) > 0:
                    topic_number = int(topic_data[0][0]) if topic_data[0] else -1
                    distance = topic_data[1][0] if len(topic_data) > 1 and topic_data[1] else 1.0
                    confidence = max(0.0, 1.0 - distance)
                    confidence = min(confidence, 1.0)

                    return {
                        "topic_number": topic_number,
                        "confidence": confidence
                    }
            except Exception as e:
                print(f"Error loading/querying model: {e}")

        # FALLBACK: Keyword-based classification when model not found
        print(f"Model not found at {model_path}. Using keyword-based classifier.")
        return classify_with_keywords(text)

    except Exception as e:
        print(f"Classification error: {e}")
        return {"topic_number": -1, "confidence": 0.0}


def classify_with_keywords(text):
    """Fallback: Simple keyword-based classification"""
    try:
        if not text or len(text.strip()) < 10:
            return {"topic_number": -1, "confidence": 0.0}

        text_lower = text.lower()

        # Define categories with keywords
        categories = {
            0: (["finance", "money", "budget", "payment", "invoice", "expense", "account", "bank"], "Finance"),
            1: (["work", "project", "task", "meeting", "deadline", "report", "email", "client"], "Work"),
            2: (["personal", "diary", "private", "note", "memo", "reminder", "family", "friend"], "Personal"),
            3: (["research", "paper", "study", "analysis", "data", "experiment", "theory", "result"], "Research"),
        }

        scores = {}
        for topic_num, (keywords, name) in categories.items():
            matches = sum(1 for kw in keywords if kw in text_lower)
            if matches > 0:
                # Score: matches divided by total keywords
                scores[topic_num] = min(matches / len(keywords), 1.0)

        if not scores:
            # No matches found
            return {"topic_number": -1, "confidence": 0.0}

        # Return best matching topic
        best_topic = max(scores.items(), key=lambda x: x[1])
        return {
            "topic_number": best_topic[0],
            "confidence": best_topic[1]
        }

    except Exception as e:
        print(f"Keyword classification error: {e}")
        return {"topic_number": -1, "confidence": 0.0}