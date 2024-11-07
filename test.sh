#!/bin/bash

# Set error handling but preserve error codes
set -o pipefail

# Debug function with timestamp
debug_log() {
    echo "[DEBUG $(date '+%H:%M:%S')] $1" >&2
}

# Function to safely handle integer operations
safe_add() {
    local -i a=${1:-0}
    local -i b=${2:-0}
    echo $((a + b))
}

# Function to initialize dashboard file with headers
init_dashboard() {
    local dashboard_file="$1"
    debug_log "Initializing dashboard file: $dashboard_file"
    {
        echo "# Molecule Test Report Dashboard"
        echo ""
        echo "## Tool Summary"
        echo "| Tool   | Version   | Binary Exists | Functional Test | OK | Changed | Skipped | Failed |"
        echo "|--------|-----------|---------------|-----------------|----|---------|---------|--------|"
    } > "$dashboard_file"
    debug_log "Dashboard initialized"
}

# Function to parse tool details from each report file
extract_tool_info() {
    local report_file="$1"
    local tool_name="$2"
    local dashboard_file="$3"

    # Extract version, binary existence, and functional test result
    local tool_version=$(grep -oP 'Toolversion:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$report_file" || echo "N/A")
    local binary_exists=$(grep -q 'Binary exists in the path' "$report_file" && echo "Yes" || echo "No")
    local functional_test=$(grep -q 'Functional test success' "$report_file" && echo "Success" || echo "Failed")

    # Initialize test counts
    declare -i ok_count=0
    declare -i changed_count=0
    declare -i skipped_count=0
    declare -i failed_count=0

    # Parse test results from "PLAY RECAP" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"PLAY RECAP"* ]]; then
            debug_log "Found PLAY RECAP marker in $report_file"
            
            # Read next line safely
            if ! read -r next_line; then
                debug_log "No more lines after PLAY RECAP in $report_file"
                continue
            fi
            
            parse_test_line "$next_line" ok_count changed_count skipped_count failed_count
        fi
    done < "$report_file"

    # Append results to dashboard
    echo "| $tool_name | $tool_version | $binary_exists | $functional_test | $ok_count | $changed_count | $skipped_count | $failed_count |" >> "$dashboard_file"
    debug_log "Appended $tool_name results to dashboard"
}

# Function to parse individual test line and accumulate states
parse_test_line() {
    local line="$1"
    local -n ok_ref="$2"
    local -n changed_ref="$3"
    local -n skipped_ref="$4"
    local -n failed_ref="$5"

    debug_log "Parsing test line: $line"
    
    local ok_temp=0
    local changed_temp=0
    local skipped_temp=0
    local failed_temp=0

    # Extract each state if present
    [[ "$line" =~ .*ok=([0-9]+).* ]] && ok_temp=${BASH_REMATCH[1]}
    [[ "$line" =~ .*changed=([0-9]+).* ]] && changed_temp=${BASH_REMATCH[1]}
    [[ "$line" =~ .*skipped=([0-9]+).* ]] && skipped_temp=${BASH_REMATCH[1]}
    [[ "$line" =~ .*failed=([0-9]+).* ]] && failed_temp=${BASH_REMATCH[1]}

    # Update totals
    ok_ref=$(safe_add "$ok_ref" "$ok_temp")
    changed_ref=$(safe_add "$changed_ref" "$changed_temp")
    skipped_ref=$(safe_add "$skipped_ref" "$skipped_temp")
    failed_ref=$(safe_add "$failed_ref" "$failed_temp")

    debug_log "Updated test counts - OK: $ok_ref, Changed: $changed_ref, Skipped: $skipped_ref, Failed: $failed_ref"
}

main() {
    debug_log "Script started"

    local dashboard_file="dashboard.md"
    init_dashboard "$dashboard_file"

    debug_log "Current directory contents:"
    ls -la >&2

    # Process each report file
    for report in molecule-test-*.txt; do
        if [[ ! -f "$report" ]]; then
            debug_log "No molecule test reports found"
            break
        fi

        debug_log "Processing report: $report"
        
        local tool_name
        tool_name=$(echo "$report" | sed 's/molecule-test-\(.*\)\.txt/\1/')
        debug_log "Processing tool: $tool_name"

        # Extract tool info and test results, and update the dashboard
        extract_tool_info "$report" "$tool_name" "$dashboard_file"
    done

    debug_log "Dashboard file contents:"
    cat "$dashboard_file" >&2

    # Display dashboard
    cat "$dashboard_file"

    # Update GitHub Actions summary if available
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        debug_log "Updating GitHub Actions summary"
        {
            echo "## Molecule Test Report Dashboard"
            cat "$dashboard_file"
        } >> "$GITHUB_STEP_SUMMARY"
    fi

    debug_log "Script completed successfully"
}

main "$@"
