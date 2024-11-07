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
    
    debug_log "Starting to parse line: $line"
    
    # Initialize temporary variables
    local version_temp=""
    local binary_available_temp=""
    local functional_test_temp=""
    local ok_temp=0
    local changed_temp=0
    local skipped_temp=0
    local failed_temp=0
    
    # Extract each value if present
    if [[ "$line" =~ .*Tools\ version:([0-9]+\.[0-9]+\.[0-9]+).* ]]; then
        version_temp="${BASH_REMATCH[1]}"
        debug_log "Found version: $version_temp"
    fi
    
    if [[ "$line" == *"Binary is present in the path"* ]]; then
        binary_available_temp="Yes"
    elif [[ "$line" == *"Binary is missing"* ]]; then
        binary_available_temp="No"
    fi
    debug_log "Binary availability: $binary_available_temp"
    
    if [[ "$line" == *"Functional testing passed"* ]]; then
        functional_test_temp="Passed"
    elif [[ "$line" == *"Functional testing failed"* ]]; then
        functional_test_temp="Failed"
    fi
    debug_log "Functional test result: $functional_test_temp"
    
    if [[ "$line" =~ .*ok=([0-9]+).* ]]; then
        ok_temp=${BASH_REMATCH[1]}
        debug_log "Found ok=$ok_temp"
    fi
    
    if [[ "$line" =~ .*changed=([0-9]+).* ]]; then
        changed_temp=${BASH_REMATCH[1]}
        debug_log "Found changed=$changed_temp"
    fi
    
    if [[ "$line" =~ .*skipped=([0-9]+).* ]]; then
        skipped_temp=${BASH_REMATCH[1]}
        debug_log "Found skipped=$skipped_temp"
    fi
    
    if [[ "$line" =~ .*failed=([0-9]+).* ]]; then
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
    # Parse command-line arguments for configuration
    local dashboard_file="dashboard.md"
    local report_pattern="molecule-test-*.txt"
    local github_actions_summary="${GITHUB_STEP_SUMMARY:-}"
    
    # Initialize dashboard
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
        if [[ ! -f "$report" ]]; then
            debug_log "No molecule test reports found"
            break
        fi
        
        debug_log "Processing report: $report"
        
        local tool_name
        tool_name=$(echo "$report" | sed 's/molecule-test-\(.*\)\.txt/\1/')
        debug_log "Processing tool: $tool_name"
        
        declare -i ok_count=0
        declare -i changed_count=0
        declare -i skipped_count=0
        declare -i failed_count=0
        local tool_version=""
        local binary_available=""
        local functional_test=""
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *"PLAY RECAP"* ]]; then
                debug_log "Found PLAY RECAP marker"
                
                # Read next line safely
                if ! read -r next_line; then
                    debug_log "No more lines after PLAY RECAP"
                    continue
                fi
                
                # Skip empty lines
                if [[ -z "$next_line" ]]; then
                    debug_log "Empty line after PLAY RECAP"
                    continue
                fi
                
                debug_log "Processing recap line: $next_line"
                parse_test_line "$next_line" tool_version binary_available functional_test ok_count changed_count skipped_count failed_count
                debug_log "After parsing - version: $tool_version, binary: $binary_available, functional: $functional_test, ok: $ok_count, changed: $changed_count, skipped: $skipped_count, failed: $failed_count"
            fi
        done < "$report"

        debug_log "Final counts for $tool_name - version: $tool_version, binary: $binary_available, functional: $functional_test, ok: $ok_count, changed: $changed_count, skipped: $skipped_count, failed: $failed_count"

        # Update totals safely
        total_tools=$(safe_add "$total_tools" 1)
        total_ok=$(safe_add "$total_ok" "$ok_count")
        total_changed=$(safe_add "$total_changed" "$changed_count")
        total_skipped=$(safe_add "$total_skipped" "$skipped_count")
        total_failed_count=$(safe_add "$total_failed_count" "$failed_count")
        
        if ((failed_count == 0)); then
            total_passed=$(safe_add "$total_passed" 1)
        else
            total_failed=$(safe_add "$total_failed" 1)
        fi

        debug_log "Writing results for $tool_name to dashboard"
        echo "| $tool_name | $tool_version | $binary_available | $functional_test | $ok_count | $changed_count | $skipped_count | $failed_count |" >> "$dashboard_file"
        debug_log "Results written successfully"
    done

    debug_log "All files processed. Adding final summary."

    # Add separator and totals
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

    debug_log "Dashboard file contents:"
    cat "$dashboard_file" >&2

    # Display dashboard
    cat "$dashboard_file"

    # Update GitHub Actions summary if available
    if [[ -n "$github_actions_summary" ]]; then
        debug_log "Updating GitHub Actions summary"
        {
            echo "## Molecule Test Report Dashboard"
            cat "$dashboard_file"
        } >> "$github_actions_summary"
    fi

    debug_log "Script completed successfully"
}

main "$@"
