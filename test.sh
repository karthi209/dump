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
    fi

    if [[ "$line" =~ ok=([0-9]+) ]]; then
        ok_temp=${BASH_REMATCH[1]}
        debug_log "Found ok=$ok_temp"
    fi
    if [[ "$line" =~ changed=([0-9]+) ]]; then
        changed_temp=${BASH_REMATCH[1]}
        debug_log "Found changed=$changed_temp"
    fi
    if [[ "$line" =~ skipped=([0-9]+) ]]; then
        skipped_temp=${BASH_REMATCH[1]}
        debug_log "Found skipped=$skipped_temp"
    fi
    if [[ "$line" =~ failed=([0-9]+) ]]; then
        failed_temp=${BASH_REMATCH[1]}
        debug_log "Found failed=$failed_temp"
    fi

    # Update references with values from the current line
    if [ -n "$version_temp" ]; then
        version_ref="$version_temp"
    fi
    if [ -n "$binary_available_temp" ]; then
        binary_available_ref="$binary_available_temp"
    fi
    if [ -n "$functional_test_temp" ]; then
        functional_test_ref="$functional_test_temp"
    fi
    ok_ref=$(safe_add "$ok_ref" "$ok_temp")
    changed_ref=$(safe_add "$changed_ref" "$changed_temp")
    skipped_ref=$(safe_add "$skipped_ref" "$skipped_temp")
    failed_ref=$(safe_add "$failed_ref" "$failed_temp")
    
    debug_log "Updated totals - version: $version_ref, binary: $binary_available_ref, functional: $functional_test_ref, ok: $ok_ref, changed: $changed_ref, skipped: $skipped_ref, failed: $failed_ref"
    return 0
}

# Function to finalize dashboard entry per tool
write_dashboard_entry() {
    local dashboard_file="$1"
    local tool="$2"
    local version="$3"
    local binary_available="$4"
    local functional_test="$5"
    local ok="$6"
    local changed="$7"
    local skipped="$8"
    local failed="$9"

    debug_log "Writing entry to dashboard for tool: $tool"
    echo "| $tool | ${version:-N/A} | ${binary_available:-N/A} | ${functional_test:-N/A} | $ok | $changed | $skipped | $failed |" >> "$dashboard_file"
}

# Main function to process each report file
process_report_file() {
    local report_file="$1"
    local dashboard_file="$2"
    local tool_name="$3"

    debug_log "Processing report file: $report_file for tool: $tool_name"

    # Initialize counters and information variables
    local version=""
    local binary_available="N/A"
    local functional_test="N/A"
    local ok=0
    local changed=0
    local skipped=0
    local failed=0

    # Parse each line in the report file
    while IFS= read -r line; do
        parse_test_line "$line" version binary_available functional_test ok changed skipped failed
    done < "$report_file"

    # Write the accumulated results to the dashboard
    write_dashboard_entry "$dashboard_file" "$tool_name" "$version" "$binary_available" "$functional_test" "$ok" "$changed" "$skipped" "$failed"
    debug_log "Finished processing report file for tool: $tool_name"
}

# Example usage
dashboard_file="dashboard.md"
init_dashboard "$dashboard_file"
process_report_file "molecule-test-allure_commandline.txt" "$dashboard_file" "Allure"

echo "Dashboard created: $dashboard_file"
