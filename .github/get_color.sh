#!/bin/bash

# Check if a file or score is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <pylint_score_or_file>"
    exit 1
fi

# Read the score from a file if a file path is provided
if [ -f "$1" ]; then
    SCORE=$(cat "$1")
else
    SCORE="$1"
fi

# Validate that SCORE is a numeric value
if ! [[ "$SCORE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Invalid score '$SCORE'. Please provide a valid numeric pylint score."
    exit 1
fi

# Determine the badge color based on the score using bc for floating-point comparison
if (( $(echo "$SCORE >= 9.0" | bc -l) )); then
    COLOR="brightgreen"
elif (( $(echo "$SCORE >= 8.0" | bc -l) )); then
    COLOR="green"
elif (( $(echo "$SCORE >= 7.0" | bc -l) )); then
    COLOR="yellowgreen"
elif (( $(echo "$SCORE >= 6.0" | bc -l) )); then
    COLOR="yellow"
else
    COLOR="red"
fi

# Output the color
echo "$COLOR"