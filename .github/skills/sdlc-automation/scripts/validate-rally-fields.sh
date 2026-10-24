#!/bin/bash
# validate-rally-fields.sh — Validates Rally issue fields before processing
# Used by the SDLC Automation Agent to ensure data quality
#
# This script validates that the extracted Rally fields meet minimum
# quality requirements before the agent proceeds with SDLC automation.
#
# Usage: Source this script or call validate_rally_data function
# This script is READ-ONLY and safe to execute without side effects.

set -euo pipefail

# --- Validation Functions ---

validate_formatted_id() {
    local id="$1"
    if [[ ! "$id" =~ ^(US|DE|TA|TC)[0-9]+$ ]]; then
        echo "ERROR: Invalid FormattedID format: '$id'"
        echo "Expected pattern: US##### or DE##### or TA##### or TC#####"
        return 1
    fi
    echo "✅ FormattedID valid: $id"
    return 0
}

validate_schedule_state() {
    local state="$1"
    case "$state" in
        "Defined"|"In-Progress"|"Completed"|"Accepted")
            echo "✅ ScheduleState valid: $state"
            ;;
        *)
            echo "ERROR: Unknown ScheduleState: '$state'"
            echo "Expected: Defined, In-Progress, Completed, or Accepted"
            return 1
            ;;
    esac

    if [ "$state" == "Accepted" ]; then
        echo "ABORT: Issue is in 'Accepted' state. Cannot modify accepted artifacts."
        return 2
    fi

    if [ "$state" == "Completed" ]; then
        echo "WARNING: Issue is already 'Completed'. User confirmation required."
        return 3
    fi

    return 0
}

validate_title() {
    local title="$1"
    if [ -z "$title" ] || [ ${#title} -lt 5 ]; then
        echo "ERROR: Title is empty or too short (min 5 chars): '$title'"
        return 1
    fi
    if [ ${#title} -gt 256 ]; then
        echo "WARNING: Title is very long (${#title} chars). Will be truncated for branch naming."
    fi
    echo "✅ Title valid: $title"
    return 0
}

validate_description() {
    local description="$1"
    if [ -z "$description" ]; then
        echo "WARNING: Description is empty. Requirements generation may lack context."
        return 0
    fi
    
    # Check for HTML-only content (common in Rally)
    local stripped
    stripped=$(echo "$description" | sed 's/<[^>]*>//g' | tr -d '[:space:]')
    if [ -z "$stripped" ] || [ "$stripped" == "&nbsp;" ]; then
        echo "WARNING: Description contains only HTML markup with no meaningful content."
        return 0
    fi
    
    echo "✅ Description valid (${#description} chars)"
    return 0
}

validate_acceptance_criteria() {
    local criteria="$1"
    if [ -z "$criteria" ]; then
        echo "WARNING: AcceptanceCriteria is empty. Agent will infer from Description."
        return 0
    fi
    echo "✅ AcceptanceCriteria present (${#criteria} chars)"
    return 0
}

# --- Main Validation ---

echo "=== Rally Fields Validation ==="
echo ""
echo "This script validates that Rally issue fields meet minimum"
echo "quality requirements for SDLC automation processing."
echo ""
echo "Validation Rules:"
echo "  - FormattedID must match pattern: (US|DE|TA|TC)[0-9]+"
echo "  - ScheduleState must not be 'Accepted'"
echo "  - Title must be at least 5 characters"
echo "  - Description should contain meaningful text"
echo "  - AcceptanceCriteria should be present (warning if empty)"
echo ""
echo "Exit codes:"
echo "  0 = All validations passed"
echo "  1 = Critical validation failure"
echo "  2 = Issue is in Accepted state (cannot proceed)"
echo "  3 = Issue is in Completed state (needs user confirmation)"
echo ""
echo "Note: This script is designed to be sourced by the agent."
echo "Call individual validate_* functions as needed."
