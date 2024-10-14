# ALL YOUR REBASE ARE BELONG TO US

Automating the sequential merging of all our feature branches into a temporary integration branch. The script starts by prompting you for two inputs: the command to run our project's tests (like `npm test` or `./run_tests.sh`), and an optional custom name for the temporary integration branch—defaulting to `temp-integration-branch` if you leave it blank.

Here's what the script does:

**Branch Ordering:** It gathers all local Git branches except `master`, sorting them by their creation date to process the oldest branches first. This ensures that we integrate changes in the order they were developed.

**Integration Loop:** For each branch in this list, the script:

- Checks out the `master` branch and creates or resets the temporary integration branch.
- Merges the current feature branch into the temporary integration branch without committing, allowing us to inspect changes before they are finalized.
- Lists all files changed in the merge, giving us immediate visibility into what's being introduced.
- Commits the merge to the temporary branch.

**Testing After Merge:** It then runs the test command you provided earlier. If the tests pass:

- The script records the merge commit hash, which is useful for potential reverts.
- Proceeds to the next branch to continue the integration process.
- Outputs a command to revert the merge if needed.

If the tests fail:

- The script automatically reverts the merge to keep the temporary branch in a stable state.
- Stops the integration process to prevent cascading failures, allowing us to address the issue before moving on.

**Logging and Output:** All output from the script—including prompts, merge details, test results, and any error messages—is logged both to the console and to a timestamped log file in the current working directory (e.g., `rebase_session_2023-10-14_15-30-00.log`). This comprehensive logging is crucial for auditing and debugging purposes.

**Exit Message:** Upon completion or if the script exits due to an error, it displays a clear, red underlined message indicating where the session log has been saved. This ensures that we always know where to find the detailed logs for that session.

**Revert Instructions:** After all branches have been processed, the script provides a list of `git revert` commands in reverse order. This is particularly helpful if we need to undo the merges due to unforeseen issues.
