import os
import json
import numpy as np
import re
from gensim.models import Word2Vec
from sklearn.datasets import fetch_20newsgroups

# --- CONFIGURATION ---
OUTPUT_DIR = "assets/models"
MODEL_DIMENSIONS = 100

# Hardcoded stopwords to match Android inference exactly
STOPWORDS = {
    'the', 'and', 'to', 'of', 'a', 'in', 'is', 'that', 'for', 'it', 'on', 'with', 'as',
    'was', 'at', 'by', 'an', 'be', 'this', 'which', 'or', 'from', 'but', 'not', 'are',
    'your', 'all', 'have', 'new', 'more', 'an', 'was', 'we', 'will', 'home', 'can',
    'us', 'about', 'if', 'page', 'my', 'has', 'search', 'free', 'but', 'our', 'one',
    'other', 'do', 'no', 'information', 'time', 'they', 'site', 'he', 'up', 'may',
    'what', 'which', 'their', 'news', 'out', 'use', 'any', 'there', 'see', 'only',
    'so', 'his', 'when', 'contact', 'here', 'business', 'who', 'web', 'also', 'now',
    'help', 'get', 'pm', 'view', 'online', 'c', 'e', 'first', 'am', 'been', 'would',
    'how', 'were', 'me', 's', 'services', 'some', 'these', 'click', 'its', 'like',
    'service', 'x', 'than', 'find', 'price', 'date', 'back', 'top', 'people', 'had',
    'list', 'name', 'just', 'over', 'state', 'year', 'day', 'into', 'email', 'two',
    'health', 'n', 'world', 're', 'next', 'used', 'go', 'b', 'work', 'last', 'most'
}

# Map 20 Newsgroups data to our Mobile Categories
CATEGORY_MAPPING = {
    'comp.graphics': 'Technology',
    'comp.os.ms-windows.misc': 'Technology',
    'comp.sys.ibm.pc.hardware': 'Technology',
    'comp.sys.mac.hardware': 'Technology',
    'comp.windows.x': 'Programming',
    'misc.forsale': 'Business',
    'rec.autos': 'Automotive',      # Mapped to new category
    'rec.motorcycles': 'Automotive',# Mapped to new category
    'rec.sport.baseball': 'Sports',
    'rec.sport.hockey': 'Sports',
    'sci.crypt': 'Technology',      # Security often falls under Tech for personal files
    'sci.electronics': 'Technology',
    'sci.med': 'Health',
    'sci.space': 'Science',
    'soc.religion.christian': 'Personal', # Religion -> Personal
    'talk.politics.guns': 'Politics',
    'talk.politics.mideast': 'Politics',
    'talk.politics.misc': 'Politics',
    'talk.religion.misc': 'Personal',
}

# ==========================================
# CUSTOM TRAINING DATA
# ==========================================
CUSTOM_DATA = [
    # 1. FINANCE
    ("invoice bill receipt tax statement total amount due payment processed transaction currency dollar", "Finance"),
    ("bank account credit debit card balance transfer wire deposit withdrawal check cheque atm", "Finance"),
    ("salary payroll earnings payslip income deduction 401k pension retirement investment stock dividend", "Finance"),
    ("financial report profit loss balance sheet audit budget quarter fiscal revenue expense", "Finance"),
    ("loan mortgage interest rate principal lender borrower debt consolidation repayment schedule", "Finance"),

    # 2. EDUCATION
    ("syllabus course curriculum semester grade score gpa transcript report card academic year", "Education"),
    ("student teacher professor faculty university college school campus classroom lecture tutorial", "Education"),
    ("assignment homework project thesis dissertation essay paper bibliography citation research study", "Education"),
    ("exam quiz test midterm final assessment question answer key solution exam preparation revision", "Education"),
    ("scholarship tuition fee admission application enrollment degree diploma certificate graduation", "Education"),

    # 3. PROGRAMMING
    ("function class void int string var const let import package return if else for while loop", "Programming"),
    ("python java dart flutter javascript typescript react nodejs html css sql database api endpoint", "Programming"),
    ("bug fix debug error exception stack trace compiler build deploy release version git commit push", "Programming"),
    ("software hardware server client network protocol http https json xml yaml config settings", "Programming"),
    ("developer engineer coding algorithm structure framework library dependency sdk ide terminal shell", "Programming"),

    # 4. LEGAL
    ("contract agreement party between undersigned witness signature date effective terms conditions clause", "Legal"),
    ("lawyer attorney legal counsel court judge jury verdict lawsuit case litigation dispute settlement", "Legal"),
    ("nda non-disclosure confidentiality memorandum understanding mou affidavit notary public sworn statement", "Legal"),
    ("will testament executor beneficiary inheritance estate power of attorney guardianship custody divorce", "Legal"),
    ("liability indemnity warranty breach termination jurisdiction governing law arbitration mediation", "Legal"),

    # 5. PERSONAL
    ("passport visa immigration citizenship naturalization travel document identification id card", "Personal"),
    ("driver license permit vehicle registration social security number ssn birth certificate marriage", "Personal"),
    ("resume cv curriculum vitae experience skills summary objective references contact profile portfolio", "Personal"),
    ("biography bio about me personal history diary journal log entry note reminder todo list", "Personal"),
    ("membership card library gym club association subscription loyalty program rewards points", "Personal"),

    # 6. HEALTH
    ("medical report diagnosis patient doctor physician nurse hospital clinic appointment prescription rx", "Health"),
    ("insurance policy claim coverage benefit deductible copay premium health care provider network", "Health"),
    ("lab test blood result xray mri scan ultrasound pathology vaccination immunization record shot", "Health"),
    ("treatment surgery operation procedure therapy medication drug dosage pharmacy instructions side effects", "Health"),
    ("symptom pain fever cough flu infection disease condition history allergy emergency ambulance", "Health"),

    # 7. TRAVEL
    ("ticket boarding pass flight airline airport gate seat departure arrival terminal baggage claim", "Travel"),
    ("hotel booking reservation accommodation check-in check-out room guest confirmation itinerary schedule", "Travel"),
    ("train bus rail transit metro subway station platform fare schedule route map directions gps", "Travel"),
    ("car rental vehicle insurance collision damage waiver pickup dropoff mileage fuel gas station", "Travel"),
    ("vacation holiday tour guide sightseeing attraction museum park beach resort cruise trip voyage", "Travel"),

    # 8. REAL ESTATE
    ("lease rental agreement tenant landlord rent deposit security apartment house home property unit", "Real Estate"),
    ("deed title ownership conveyance closing settlement statement escrow title insurance appraisal survey", "Real Estate"),
    ("utility bill electricity water gas power heat internet cable wifi trash sewage service provider", "Real Estate"),
    ("maintenance repair request inspection renovation contractor plumber electrician carpenter invoice work", "Real Estate"),
    ("mortgage deed trust foreclosure eviction notice lien easement zoning permit construction plan", "Real Estate"),

    # 9. AUTOMOTIVE
    ("vehicle registration title vin chassis number make model year color plate tag sticker decal", "Automotive"),
    ("car insurance policy auto coverage liability collision comprehensive deductible claim accident report", "Automotive"),
    ("repair maintenance service oil change tire rotation brake inspection mechanic shop garage estimate", "Automotive"),
    ("parking ticket citation violation fine towing impound traffic court speeding red light camera", "Automotive"),
    ("manual handbook warranty user guide specifications parts accessories catalog dealer showroom sales", "Automotive"),
]

def clean_and_tokenize(text):
    # Remove emails and weird chars
    text = re.sub(r'\S+@\S+', '', text)
    text = re.sub(r'\s+', ' ', text)
    # Tokenize (3+ chars only)
    tokens = re.findall(r'\b[a-z]{3,}\b', text.lower())
    # Remove stopwords
    return [t for t in tokens if t not in STOPWORDS]

def main():
    if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)

    print("1. Loading Dataset (20 Newsgroups)...")
    newsgroups = fetch_20newsgroups(subset='all', remove=('headers', 'footers', 'quotes'))

    documents = []
    labels = []

    for i, text in enumerate(newsgroups.data):
        original_cat = newsgroups.target_names[newsgroups.target[i]]
        if original_cat in CATEGORY_MAPPING:
            tokens = clean_and_tokenize(text)
            if tokens:
                documents.append(tokens)
                labels.append(CATEGORY_MAPPING[original_cat])

    print(f"2. Adding {len(CUSTOM_DATA)} custom training samples...")
    for text, label in CUSTOM_DATA:
        tokens = clean_and_tokenize(text)
        # Weight multiplier: Repeat custom data 30 times so it overpowers the news data
        for _ in range(30):
            documents.append(tokens)
            labels.append(label)

    print(f"   Total Docs: {len(documents)}")

    print("3. Training Word2Vec Model...")
    model = Word2Vec(sentences=documents, vector_size=MODEL_DIMENSIONS, window=5, min_count=2, workers=4, epochs=20)

    print("4. Calculating Category Centroids...")
    unique_labels = sorted(list(set(labels)))
    label_to_id = {label: i for i, label in enumerate(unique_labels)}

    centroids = np.zeros((len(unique_labels), MODEL_DIMENSIONS), dtype=np.float32)
    counts = np.zeros(len(unique_labels))

    for doc_tokens, label in zip(documents, labels):
        vectors = [model.wv[w] for w in doc_tokens if w in model.wv]
        if not vectors: continue
        doc_vec = np.mean(vectors, axis=0)
        cat_id = label_to_id[label]
        centroids[cat_id] += doc_vec
        counts[cat_id] += 1

    for i in range(len(unique_labels)):
        if counts[i] > 0:
            centroids[i] /= counts[i]
        norm = np.linalg.norm(centroids[i])
        if norm > 0: centroids[i] /= norm

    print("5. Exporting Assets...")
    vocab = {word: i for i, word in enumerate(model.wv.index_to_key)}
    with open(os.path.join(OUTPUT_DIR, "vocab.json"), "w", encoding="utf-8") as f:
        json.dump(vocab, f)

    np.save(os.path.join(OUTPUT_DIR, "word_vectors.npy"), model.wv.vectors.astype(np.float32))
    np.save(os.path.join(OUTPUT_DIR, "topic_vectors.npy"), centroids)

    topic_map = {str(i): label for i, label in enumerate(unique_labels)}
    topic_map["default"] = "General"
    with open(os.path.join(OUTPUT_DIR, "topic_map.json"), "w", encoding="utf-8") as f:
        json.dump(topic_map, f, indent=2)

main()