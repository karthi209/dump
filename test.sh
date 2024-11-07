#!/bin/bash

# Function to initialize the dashboard file with headers
init_dashboard() {
    local dashboard_file="$1"
    echo "# Molecule Test Report Dashboard" > "$dashboard_file"
    echo "" >> "$dashboard_file"
    echo "## Tool Summary" >> "$dashboard_file"
    echo "| Tool   | Version   | Binary Exists | Functional Test |" >> "$dashboard_file"
    echo "|--------|-----------|---------------|-----------------|" >> "$dashboard_file"
}

# Function to extract and report on tool information
extract_tool_info() {
    local report_file="$1"
    local dashboard_file="$2"
    local tool_name="$3"

    # Extract Toolversion
    echo "DEBUG: Searching for 'Toolversion:' in $report_file"
    local tool_version=$(grep -oP 'Toolversion:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$report_file")

    # Extract Binary Existence
    echo "DEBUG: Searching for 'Binary exists' in $report_file"
    local binary_exists=$(grep -oP 'Binary exists in the path' "$report_file" && echo "Yes" || echo "No")

    # Extract Functional Test Result
    echo "DEBUG: Searching for 'Functional test success' in $report_file"
    local functional_test=$(grep -oP 'Functional test success' "$report_file" && echo "Success" || echo "Failed")

    # Fill in "N/A" if any of the fields were not found
    [[ -z "$tool_version" ]] && tool_version="N/A"
    [[ -z "$binary_exists" ]] && binary_exists="No"
    [[ -z "$functional_test" ]] && functional_test="Failed"

    # Append tool info to dashboard
    echo "| $tool_name | $tool_version | $binary_exists | $functional_test |" >> "$dashboard_file"
}

# Main script logic
dashboard_file="dashboard.md"
init_dashboard "$dashboard_file"
extract_tool_info "molecule-test-allure_commandline.txt" "$dashboard_file" "Allure"

echo "Dashboard created: $dashboard_file"
