#!/bin/bash

echo "        ╔═╗╦  ╦    ╦ ╦╔═╗╦ ╦╦═╗  ╔╗ ╔═╗╔═╗╔═╗ ";
echo "        ╠═╣║  ║    ╚╦╝║ ║║ ║╠╦╝  ╠╩╗╠═╣╚═╗║╣  ";
echo "        ╩ ╩╩═╝╩═╝   ╩ ╚═╝╚═╝╩╚═  ╚═╝╩ ╩╚═╝╚═╝ ";
echo "╔═╗╦═╗╔═╗  ╔╗ ╔═╗╦  ╔═╗╔╗╔╔═╗  ╔╦╗╔═╗  ╦ ╦╔═╗┬";
echo "╠═╣╠╦╝║╣   ╠╩╗║╣ ║  ║ ║║║║║ ╦   ║ ║ ║  ║ ║╚═╗│";
echo "╩ ╩╩╚═╚═╝  ╚═╝╚═╝╩═╝╚═╝╝╚╝╚═╝   ╩ ╚═╝  ╚═╝╚═╝o";
echo "(incremental git rebase w rollback protection)";
echo "                         - Dan Houseman - 2024";

# Exit immediately if a command exits with a non-zero status
set -e

# Generate log file name with current date and time
LOG_FILE="rebase_session_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Get full path to the log file
FULL_LOG_PATH="$(pwd)/$LOG_FILE"

# Redirect all output to console and log file
exec > >(tee -a "$LOG_FILE") 2>&1

# ANSI color codes for red underlined text
RED='\033[4;31m'
NC='\033[0m' # No Color

# Function to display the exit message
function exit_message {
    echo -e "${RED}A SESSION LOG HAS BEEN SAVED AT ${FULL_LOG_PATH}${NC}"
}
trap exit_message EXIT

# Prompt for test command
read -p "Command to run tests: " TEST_COMMAND

# Prompt for temporary integration branch name
read -p "Custom temporary integration branch name (Leave blank to default to temp-integration-branch): " TEMP_BRANCH

# Set default if TEMP_BRANCH is empty
if [ -z "$TEMP_BRANCH" ]; then
    TEMP_BRANCH="temp-integration-branch"
fi

# Get the list of local branches sorted by creation date, excluding master
branches=$(git for-each-ref --sort=committerdate refs/heads/ --format='%(refname:short)' | grep -v '^master$')

echo "Branches to process in order:"
echo "$branches"

# Checkout master branch
echo "Checking out master branch..."
git checkout master

# Create or reset the temporary integration branch
if git show-ref --quiet refs/heads/$TEMP_BRANCH; then
    # If the branch exists, delete it
    git branch -D "$TEMP_BRANCH"
fi
git checkout -b "$TEMP_BRANCH"

# Array to store merge commit hashes for revert commands
declare -a merge_commits=()

# Process each branch
for branch in $branches; do
    echo "======================================"
    echo "Processing branch: $branch"

    # Merge branch into temp-integration-branch without committing
    echo "Merging $branch into $TEMP_BRANCH without committing"
    git merge --no-ff --no-commit "$branch"

    # Get files changed
    files_changed=$(git diff --name-only --cached)

    echo "Files changed in branch $branch:"
    echo "$files_changed"

    # Commit the merge
    echo "Committing the merge..."
    git commit -m "Merge branch '$branch' into $TEMP_BRANCH"

    # Get the new commit hash

    merge_commit=$(git rev-parse HEAD)
    echo "Merge commit hash created: $merge_commit"

    # Run tests
    echo "╦═╗╦ ╦╔╗╔╔╗╔╦╔╗╔╔═╗  ╔╦╗╔═╗╔═╗╔╦╗╔═╗   ";
    echo "╠╦╝║ ║║║║║║║║║║║║ ╦   ║ ║╣ ╚═╗ ║ ╚═╗   ";
    echo "╩╚═╚═╝╝╚╝╝╚╝╩╝╚╝╚═╝   ╩ ╚═╝╚═╝ ╩ ╚═╝ooo";
    if $TEST_COMMAND; then
        echo "Tests passed for branch $branch"

        # Record merge commit hash for revert command
        merge_commits+=("$merge_commit")

        # Output revert command
        echo "To revert this merge, run: git revert $merge_commit"

        # Output the branch name and files changed
        echo "Branch merged: $branch"
        echo "Files changed:"
        echo "$files_changed"
    else
        echo "${RED}Tests failed for branch $branch${NC}"

        # Revert the merge
        git revert --no-edit "$merge_commit"
        echo "Reverted merge commit $merge_commit"

        echo "Stopping script due to failed tests."
        break
    fi
done

echo "======================================================"
echo "╔═╗╦  ╦    ╦ ╦╔═╗╦ ╦╦═╗  ╦═╗╔═╗╔╗ ╔═╗╔═╗╔═╗  ╔═╗╦═╗╔═╗";
echo "╠═╣║  ║    ╚╦╝║ ║║ ║╠╦╝  ╠╦╝║╣ ╠╩╗╠═╣╚═╗║╣   ╠═╣╠╦╝║╣ ";
echo "╩ ╩╩═╝╩═╝   ╩ ╚═╝╚═╝╩╚═  ╩╚═╚═╝╚═╝╩ ╩╚═╝╚═╝  ╩ ╩╩╚═╚═╝";
echo "╦╔╗╔╔╦╗╔═╗╔═╗╦═╗╔═╗╔╦╗╔═╗╔╦╗  ╔═╗╔═╗╔╦╗╔═╗╦  ╔═╗╔╦╗╔═╗";
echo "║║║║ ║ ║╣ ║ ╦╠╦╝╠═╣ ║ ║╣  ║║  ║  ║ ║║║║╠═╝║  ║╣  ║ ║╣ ";
echo "╩╝╚╝ ╩ ╚═╝╚═╝╩╚═╩ ╩ ╩ ╚═╝═╩╝  ╚═╝╚═╝╩ ╩╩  ╩═╝╚═╝ ╩ ╚═╝";
echo "======================================================"

# Output all revert commands in reverse order
echo "To revert all merges, run the following commands in reverse order:"
for (( idx=${#merge_commits[@]}-1 ; idx>=0 ; idx-- )); do
    echo "git revert ${merge_commits[$idx]}"
done
