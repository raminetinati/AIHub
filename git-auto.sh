#!/bin/bash

# --- 1. Safety Check ---
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not a git repository."
    exit 1
fi

# --- 2. Get Branch Name ---
# We get this once at the start to ensure we push to the correct place
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    echo "Error: Could not determine current branch."
    exit 1
fi

echo "Targeting branch: $CURRENT_BRANCH"

# --- 3. The Loop ---
# We read the status line by line
git status --porcelain | while read -r line; do
    
    # 1. clean up the filename
    FILE_PATH="${line:3}"           # Remove status code (first 3 chars)
    FILE_PATH="${FILE_PATH%\"}"     # Remove trailing quote if present
    FILE_PATH="${FILE_PATH#\"}"     # Remove leading quote if present

    if [ -n "$FILE_PATH" ]; then
        echo "------------------------------------------------"
        echo "Processing: $FILE_PATH"

        # 2. Add
        git add "$FILE_PATH"

        # 3. Commit
        # We capture the output to keep the terminal clean, unless it fails
        if git commit -m "Update: $FILE_PATH" > /dev/null; then
            echo " - Committed."
        else
            echo " - Commit failed (maybe no changes?). Skipping."
            continue
        fi

        # 4. Push
        echo " - Pushing..."
        if git push origin "$CURRENT_BRANCH"; then
            echo " - Push Successful."
        else
            echo " - Push Failed. Retrying in 2 seconds..."
            sleep 2
            git push origin "$CURRENT_BRANCH"
        fi
    fi
done

echo "------------------------------------------------"
echo "Done. All files processed."
