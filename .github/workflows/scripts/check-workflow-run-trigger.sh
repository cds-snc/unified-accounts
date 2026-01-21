#!/bin/bash
set -euo pipefail

#
# Given a directory of GitHub workflows, check that all workflows using a
# 'workflow_run' trigger are valid.
#

# Requires yq (https://github.com/mikefarah/yq)
# Directory containing the workflow files
DEFAULT_WORKFLOW_DIR="./.github/workflows"
WORKFLOW_DIR="${1:-$DEFAULT_WORKFLOW_DIR}"

# Build a mapping of workflow names to file names
declare -A workflow_names_to_files

for file in "$WORKFLOW_DIR"/*.yml; do
    if [ -f "$file" ]; then
        WORKFLOW_NAME=$(yq '.name' "$file")
        if [ -n "$WORKFLOW_NAME" ] && [ "$WORKFLOW_NAME" != "null" ]; then
            workflow_names_to_files["$WORKFLOW_NAME"]="$file"
        fi
    fi
done

# Check workflows with 'workflow_run' triggers
for file in "$WORKFLOW_DIR"/*.yml; do
    echo "Checking file: $file"
    if [ -f "$file" ]; then
        # Get workflows listed in the 'workflow_run' trigger
        workflows=$(yq '.on.workflow_run.workflows[]' "$file")
        if [ -n "$workflows" ]; then
            while IFS= read -r workflow; do
                # Skip if the workflow name is empty
                if [ -z "$workflow" ]; then
                    continue
                fi
                echo "Checking for named workflow: $workflow"
                # Check if the workflow exists in other files
                found=false
                for name in "${!workflow_names_to_files[@]}"; do
                    if [ "$name" == "$workflow" ] && [ "${workflow_names_to_files[$name]}" != "$file" ]; then
                        found=true
                        break
                    fi
                done
                if [ "$found" = false ]; then
                    echo "Error: Workflow '$workflow' referenced in '$file' does not exist in any other workflow files."
                    exit 1
                fi
            done <<< "$workflows"
        fi
    fi
done

echo "All referenced workflows exist."