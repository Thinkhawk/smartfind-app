import json

# Load the words definition
try:
    with open("assets/models/topic_words.json", "r") as f: # Check path
        data = json.load(f)
except:
    with open("topic_words.json", "r") as f:
        data = json.load(f)

# These are the IDs from your Android Logs
target_ids = ["231", "977", "519", "32"]

print(f"{'ID':<6} | {'Top Words inside this Topic'}")
print("-" * 60)

for pid in target_ids:
    words = data.get(pid, ["NOT FOUND"])
    print(f"{pid:<6} | {words[:10]}")