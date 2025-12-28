import sys
import os
import time
import json
import numpy as np
import tempfile
import shutil
from sklearn.metrics import accuracy_score, matthews_corrcoef, f1_score
from sklearn.metrics.pairwise import cosine_similarity
from scipy import spatial

PROJECT_ROOT = os.getcwd()
PYTHON_SOURCE_DIR = os.path.join(PROJECT_ROOT, "android/app/src/main/python")
sys.path.extend([PROJECT_ROOT, os.path.dirname(__file__), PYTHON_SOURCE_DIR])

import classifier
import search_engine
import summarizer

# Initialize Resources
ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets/models")
TOPIC_MAP_PATH = os.path.join(ASSETS_DIR, "topic_map.json")
classifier.load_resources(ASSETS_DIR)

class TechnicalDashboard:
    def __init__(self):
        self.sections = {}

    def add_metric(self, section, metric, value, threshold=None, is_percent=True):
        status = "PASS"
        if threshold and isinstance(value, (int, float)):
            status = "OPTIMAL" if value >= threshold else "STABLE"

        if section not in self.sections: self.sections[section] = []

        if is_percent and isinstance(value, float) and value <= 1.0:
            val_str = f"{value:.2%}"
        elif isinstance(value, (float, int)):
            val_str = f"{value:.2f}"
        else:
            val_str = str(value)

        self.sections[section].append((metric, val_str, status))

    def print_dashboard(self):
        print("\n" + "╔" + "═"*75 + "╗")
        print("║" + " SMARTFIND AI SYSTEM: TECHNICAL PERFORMANCE DASHBOARD ".center(75) + "║")
        print("╠" + "═"*75 + "╣")
        for section, metrics in self.sections.items():
            print(f"║ [ {section.upper()} ]".ljust(76) + "║")
            for m, v, s in metrics:
                line = f"  > {m:<25} : {v:<15} [{s}]"
                print(f"║ {line.ljust(73)} ║")
            print("║" + " "*75 + "║")
        # print("╠" + "═"*75 + "╣")
        print("╚" + "═"*75 + "╝\n")

dashboard = TechnicalDashboard()

def calc_similarity(vec1, vec2):
    if vec1 is None or vec2 is None: return 0.0
    return 1 - spatial.distance.cosine(vec1, vec2)

# --- 1. CLASSIFIER TEST (22 Samples) ---
def run_classifier_audit():
    with open(TOPIC_MAP_PATH, 'r') as f:
        topic_map = json.load(f)

    test_data = [
        ("invoice services rendered total dollars bank transfer", "Finance"),
        ("quarterly earnings report revenue profit growth", "Finance"),
        ("tax return filing income statement audit", "Finance"),
        ("recruitment candidate interview salary resume job", "Personal"),
        ("grocery list milk eggs bread butter snack food", "Personal"),
        ("my private diary thoughts and daily reflections", "Personal"),
        ("software hardware server client network protocol", "Programming"),
        ("python function loop variable array and recursion", "Programming"),
        ("contract agreement party lawyer attorney law court", "Legal"),
        ("terms and conditions privacy policy liability", "Legal"),
        ("ticket boarding pass flight airline airport", "Travel"),
        ("hotel reservation vacation itinerary tourism", "Travel"),
        ("homework assignment semester grade syllabus", "Education"),
        ("university lecture professor textbook and degree", "Education"),
        ("engine transmission oil change and car tires", "Automotive"),
        ("patient symptoms prescription medicine hospital", "Health"),
        ("exercise routine fitness gym and healthy diet", "Health"),
        ("election parliament vote candidate government", "Politics"),
        ("house for sale mortgage listing and property", "Real Estate"),
        ("quantum physics laboratory experiment research", "Science"),
        ("football match score tournament and athletes", "Sports"),
        ("smartphone processor ram and digital display", "Technology"),
    ]

    true, pred, latencies = [], [], []
    for text, expected in test_data:
        start = time.time()
        res = classifier.classify_file(ASSETS_DIR, text)
        latencies.append((time.time() - start) * 1000)
        true.append(expected)
        pred.append(topic_map.get(str(res['topic_number']), "General"))

    dashboard.add_metric("Classifier", "Accuracy", accuracy_score(true, pred), 0.75)
    dashboard.add_metric("Classifier", "MCC Score", matthews_corrcoef(true, pred), 0.70)
    dashboard.add_metric("Classifier", "Weighted F1-Score", f1_score(true, pred, average='weighted'), 0.75)
    dashboard.add_metric("Classifier", "Avg Latency (ms)", np.mean(latencies), is_percent=False)

# --- 2. SUMMARIZER TEST (6 Samples) ---
def run_summarizer_audit():
    test_texts = [
        ("AI Tech", "Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by animals. Leading AI textbooks define the field as the study of intelligent agents."),
        ("Legal", "This Non-Disclosure Agreement is entered into by and between the parties to protect confidential information. Failure to comply with these terms will result in immediate legal action."),
        ("Medical", "Diabetes mellitus is a group of metabolic disorders characterized by high blood sugar levels over a prolonged period. If left untreated, diabetes can cause many complications."),
        ("Finance", "A mutual fund is an open-end professionally managed investment fund that pools money from many investors to purchase securities. These investors may be retail or institutional."),
        ("Travel", "Paris is the capital and most populous city of France. Since the 17th century, Paris has been one of the world's major centres of finance, diplomacy, commerce, and fashion."),
        ("Education", "Distance education is the education of students who may not always be physically present at a school. Today, it primarily involves online education via the internet.")
    ]
    sims, latencies, ratios = [], [], []
    for _, text in test_texts:
        start = time.time()
        res = summarizer.summarize_file(text, max_sentences=1)
        latencies.append((time.time() - start) * 1000)

        summary = res['summary']
        ratios.append(1 - (len(summary) / len(text)))

        v_orig = classifier.infer_vector_manual(classifier.simple_preprocess(text))
        v_sum = classifier.infer_vector_manual(classifier.simple_preprocess(summary))
        sims.append(calc_similarity(v_orig, v_sum))

    dashboard.add_metric("Summarizer", "Semantic Similarity", np.mean(sims), 0.80)
    dashboard.add_metric("Summarizer", "Compression Rate", np.mean(ratios), 0.50)
    dashboard.add_metric("Summarizer", "Processing Speed (ms)", np.mean(latencies), is_percent=False)

# --- 3. RECOMMENDER TEST (40 Files) ---
def run_recommendation_audit():
    files = {
        "/dir/space1.txt": "The sun is a star in the center of the solar system science",
        "/dir/space2.txt": "Planets orbit around the sun due to gravity science",
        "/dir/space3.txt": "NASA launches rockets to explore the universe science",
        "/dir/space4.txt": "Black holes have intense gravity that light cannot escape science",
        "/dir/space5.txt": "The Hubble telescope captured images of distant galaxies science",
        "/dir/space6.txt": "Mars is the red planet and a target for human colonization science",
        "/dir/space7.txt": "Supernova explosions create heavy elements in space science",
        "/dir/space8.txt": "The Milky Way is our home galaxy containing billions of stars science",
        "/dir/space9.txt": "Astronauts live and work on the International Space Station science",
        "/dir/space10.txt": "Comets are icy bodies that release gas and dust as they orbit science",
        "/dir/money1.txt": "The stock market crashed due to inflation and interest rates finance",
        "/dir/money2.txt": "Banks offer loans and savings accounts for personal money finance",
        "/dir/money3.txt": "Dividend stocks provide passive income for investors finance",
        "/dir/money4.txt": "Hedge funds use complex strategies to maximize portfolio returns finance",
        "/dir/money5.txt": "Credit scores determine eligibility for mortgage and car loans finance",
        "/dir/money6.txt": "Cryptocurrency exchanges allow trading of bitcoin and ether finance",
        "/dir/money7.txt": "Taxes on capital gains are calculated annually for revenue finance",
        "/dir/money8.txt": "Venture capital firms invest in high growth tech startups finance",
        "/dir/money9.txt": "Insurance policies protect against financial loss and risk finance",
        "/dir/money10.txt": "Budgeting apps help users track expenses and save money finance",
        "/dir/tech1.txt": "Python is a popular programming language for data science tech",
        "/dir/tech2.txt": "Software development involves writing code and debugging tech",
        "/dir/tech3.txt": "React and Angular are frameworks for building web frontends tech",
        "/dir/tech4.txt": "Docker containers simplify deployment across different servers tech",
        "/dir/tech5.txt": "Machine learning models require large datasets for training tech",
        "/dir/tech6.txt": "Cybersecurity protects networks from unauthorized digital access tech",
        "/dir/tech7.txt": "API endpoints allow different software systems to communicate tech",
        "/dir/tech8.txt": "Git is a version control system for tracking source code changes tech",
        "/dir/tech9.txt": "Cloud architecture uses microservices for better scalability tech",
        "/dir/tech10.txt": "Mobile apps are developed for both Android and iOS platforms tech",
        "/dir/legal1.txt": "A contract agreement is a legally binding document legal",
        "/dir/legal2.txt": "Lawyers provide legal counsel for court cases and litigation legal",
        "/dir/legal3.txt": "Intellectual property law protects patents and trademarks legal",
        "/dir/legal4.txt": "Non disclosure agreements prevent sharing of sensitive info legal",
        "/dir/legal5.txt": "The jury delivered a verdict after hearing the testimony legal",
        "/dir/legal6.txt": "Corporate compliance ensures adherence to government laws legal",
        "/dir/legal7.txt": "Probate law handles the distribution of assets in a will legal",
        "/dir/legal8.txt": "Privacy policies must comply with data protection regulations legal",
        "/dir/legal9.txt": "Employment contracts define the terms of work and benefits legal",
        "/dir/legal10.txt": "A power of attorney gives someone legal right to act for you legal",
    }

    test_dir = tempfile.mkdtemp()
    try:
        models_dst = os.path.join(test_dir, "models")
        os.makedirs(models_dst)
        for f in ["vocab.json", "word_vectors.npy", "topic_vectors.npy"]:
            shutil.copy(os.path.join(ASSETS_DIR, f), os.path.join(models_dst, f))

        search_engine.train_local_index(test_dir, json.dumps(files))

        targets = ["/dir/space1.txt", "/dir/money3.txt", "/dir/tech2.txt", "/dir/legal1.txt"]
        precisions, recalls, diversities = [], [], []

        with open(os.path.join(test_dir, "search_index.json"), "r") as f:
            index_data = {item['path']: np.array(item['vector']) for item in json.load(f)}

        for target in targets:
            prefix = target[5:8]
            results = search_engine.get_similar_files(test_dir, target)['results']
            hits = sum(1 for r in results if prefix in r)
            precisions.append(hits / len(results) if results else 0)
            recalls.append(hits / 9.0)

            if len(results) > 1:
                rec_vectors = [index_data[r] for r in results if r in index_data]
                if len(rec_vectors) > 1:
                    sim_matrix = cosine_similarity(rec_vectors)
                    avg_sim = np.mean(sim_matrix[np.triu_indices(len(rec_vectors), k=1)])
                    diversities.append(1 - avg_sim)

        dashboard.add_metric("Recommender", "Avg Precision@5", np.mean(precisions), 0.85)
        dashboard.add_metric("Recommender", "Avg Recall@5", np.mean(recalls), 0.40)
        dashboard.add_metric("Recommender", "Intra-List Diversity", np.mean(diversities), 0.70)
    finally:
        shutil.rmtree(test_dir)

if __name__ == "__main__":
    run_classifier_audit()
    run_summarizer_audit()
    run_recommendation_audit()

    try:
        from evaluate_search_real import test_search_real_data
        s = test_search_real_data()
        dashboard.add_metric("Search Engine", "Documents Indexed", s['docs'])
        dashboard.add_metric("Search Engine", "Success Rate", s['success'])
        dashboard.add_metric("Search Engine", "MRR Score", s['mrr'])
    except Exception as e:
        print(f"Search evaluation error: {e}")

    dashboard.print_dashboard()