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

# Function to initialize dashboard file with header
init_dashboard() {
    local dashboard_file="$1"
    debug_log "Initializing dashboard file: $dashboard_file"
    {
        echo "# Molecule Test Report Dashboard"
        echo ""
        echo "## Test Results"
        echo "| Tool | Version | Binary Available | Functional Test | OK | Changed | Skipped | Failed |"
        echo "|------|---------|------------------|-----------------|-----|---------|---------|--------|"
    } > "$dashboard_file"
    debug_log "Dashboard initialized"
}

# Function to parse test line and accumulate all states
parse_test_line() {
    local line="$1"
    local -n version_ref="$2"
    local -n binary_available_ref="$3"
    local -n functional_test_ref="$4"
    local -n ok_ref="$5"
    local -n changed_ref="$6"
    local -n skipped_ref="$7"
    local -n failed_ref="$8"
    
    debug_log "Parsing line: $line"
    
    # Temporary variables for current line values
    local version_temp=""
    local binary_available_temp=""
    local functional_test_temp=""
    local ok_temp=0
    local changed_temp=0
    local skipped_temp=0
    local failed_temp=0

    # Match patterns based on log image provided
    if [[ "$line" == *"[instance_git]"* ]]; then
        if [[ "$line" == *"ToolVersion:"* ]]; then
            if [[ "$line" =~ ToolVersion:([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                version_temp="${BASH_REMATCH[1]}"
                debug_log "Found version: $version_temp"
            fi
        elif [[ "$line" == *"Binary exists in the path"* ]]; then
            binary_available_temp="Yes"
            debug_log "Binary available: Yes"
        elif [[ "$line" == *"Binary is missing"* ]]; then
            binary_available_temp="No"
            debug_log "Binary available: No"
        elif [[ "$line" == *"Functional test success"* ]]; then
            functional_test_temp="Passed"
            debug_log "Functional test: Passed"
        elif [[ "$line" == *"Functional test failure"* ]]; then
            functional_test_temp="Failed"
            debug_log "Functional test: Failed"
        fi
    elif [[ "$line" =~ ok=([0-9]+) ]]; then
        ok_temp=${BASH_REMATCH[1]}
        debug_log "Found ok=$ok_temp"
    elif [[ "$line" =~ changed=([0-9]+) ]]; then
        changed_temp=${BASH_REMATCH[1]}
        debug_log "Found changed=$changed_temp"
    elif [[ "$line" =~ skipped=([0-9]+) ]]; then
        skipped_temp=${BASH_REMATCH[1]}
        debug_log "Found skipped=$skipped_temp"
    elif [[ "$line" =~ failed=([0-9]+) ]]; then
        failed_temp=${BASH_REMATCH[1]}
        debug_log "Found failed=$failed_temp"
    fi

    # Assign values to output variables
    version_ref="$version_temp"
    binary_available_ref="$binary_available_temp"
    functional_test_ref="$functional_test_temp"
    ok_ref=$(safe_add "$ok_ref" "$ok_temp")
    changed_ref=$(safe_add "$changed_ref" "$changed_temp")
    skipped_ref=$(safe_add "$skipped_ref" "$skipped_temp")
    failed_ref=$(safe_add "$failed_ref" "$failed_temp")
    
    debug_log "Updated totals - version: $version_ref, binary: $binary_available_ref, functional: $functional_test_ref, ok: $ok_ref, changed: $changed_ref, skipped: $skipped_ref, failed: $failed_ref"
    return 0
}

main() {
    # Initialize dashboard
    local dashboard_file="dashboard.md"
    local report_pattern="molecule-test-*.txt"
    local github_actions_summary="${GITHUB_STEP_SUMMARY:-}"
    
    init_dashboard "$dashboard_file"
    
    # Declare variables to track overall test results
    declare -i total_tools=0
    declare -i total_passed=0
    declare -i total_failed=0
    declare -i total_ok=0
    declare -i total_changed=0
    declare -i total_skipped=0
    declare -i total_failed_count=0
    
    # Process each report file
    for report in $report_pattern; do
        [[ ! -f "$report" ]] && debug_log "No molecule test reports found" && break
        
        debug_log "Processing report: $report"
        
        local tool_name=$(sed 's/molecule-test-\(.*\)\.txt/\1/' <<< "$report")
        debug_log "Processing tool: $tool_name"
        
        # Initialize individual test counts
        declare -i ok_count=0
        declare -i changed_count=0
        declare -i skipped_count=0
        declare -i failed_count=0
        local tool_version=""
        local binary_available=""
        local functional_test=""
        
        while IFS= read -r line; do
            parse_test_line "$line" tool_version binary_available functional_test ok_count changed_count skipped_count failed_count
        done < "$report"

        debug_log "Final counts for $tool_name - version: $tool_version, binary: $binary_available, functional: $functional_test, ok: $ok_count, changed: $changed_count, skipped: $skipped_count, failed: $failed_count"

        # Update totals
        total_tools=$(safe_add "$total_tools" 1)
        total_ok=$(safe_add "$total_ok" "$ok_count")
        total_changed=$(safe_add "$total_changed" "$changed_count")
        total_skipped=$(safe_add "$total_skipped" "$skipped_count")
        total_failed_count=$(safe_add "$total_failed_count" "$failed_count")
        
        [[ "$functional_test" == "Passed" ]] && total_passed=$(safe_add "$total_passed" 1) || total_failed=$(safe_add "$total_failed" 1)

        echo "| $tool_name | $tool_version | $binary_available | $functional_test | $ok_count | $changed_count | $skipped_count | $failed_count |" >> "$dashboard_file"
    done

    # Add totals and summary
    {
        echo "|------|---------|------------------|-----------------|-----|---------|---------|--------|"
        echo "| **TOTALS** | - | - | - | **$total_ok** | **$total_changed** | **$total_skipped** | **$total_failed_count** |"
        echo ""
        echo "## Summary"
        echo "| Metric | Count |"
        echo "|--------|-------|"
        echo "| Total Tools | $total_tools |"
        echo "| Passed | $total_passed |"
        echo "| Failed | $total_failed |"
    } >> "$dashboard_file"

    # Display and optionally update GitHub Actions summary
    cat "$dashboard_file"
    [[ -n "$github_actions_summary" ]] && cat "$dashboard_file" >> "$github_actions_summary"
    debug_log "Script completed successfully"
}

main "$@"
