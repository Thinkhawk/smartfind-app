import os

# Define the correct content for each file
debug_content = """#include "Generated.xcconfig"
#include "../Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"

// OVERRIDE: Force Flutter to allow arm64 on simulators
EXCLUDED_ARCHS[sdk=iphonesimulator*]=
"""

release_content = """#include "Generated.xcconfig"
#include "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"

// OVERRIDE: Force Flutter to allow arm64 on simulators
EXCLUDED_ARCHS[sdk=iphonesimulator*]=
"""

# Define paths
ios_flutter_dir = os.path.join("ios", "Flutter")
debug_path = os.path.join(ios_flutter_dir, "Debug.xcconfig")
release_path = os.path.join(ios_flutter_dir, "Release.xcconfig")

# Write the files
print(f"Fixing {debug_path}...")
with open(debug_path, "w") as f:
    f.write(debug_content)

print(f"Fixing {release_path}...")
with open(release_path, "w") as f:
    f.write(release_content)

print("✅ Configuration files fixed.")