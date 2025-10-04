#!/bin/bash
#
# Autocat Training - Automated Password Recovery Testing Tool
# Optimizes password cracking sequences using multiple wordlists and rules
#

# Configuration
CONFIG_FILE="config.json"
DEFAULT_MASK="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"
DEFAULT_OUTPUT_DIR="results"
DEFAULT_TIMEOUT_SECONDS=3600  # 1 hour per cracking method by default

# Display usage information
usage() {
    cat << EOF
Usage: $0 -m <hash_type> -l <hash_file> [-o <output_dir>] [-t <timeout>] [-h]

ℹ️ You must specify in config.json the wordlists, the rules, and the amount of brute force you want to use and their paths.

Options:
    -m <hash_type>    Hashcat hash type (e.g., 0 for MD5, 1000 for NTLM)
    -p <hash_file>    Path to file containing hashes to crack
    -o <output_dir>   Output directory for results (default: ./results)
    -t <timeout>      Maximum cracking time (in seconds) for Hashcat per cracking method (default: 1h)
    -h                Display this help message

Examples:
    $0 -m 1000 -p hashes.txt

EOF
}

# Parse command line arguments
while getopts 'h:m:p:o:t:' opt; do
    case "${opt}" in
        m) HASH_TYPE="${OPTARG}" ;;
        p) HASH_FILE="${OPTARG}" ;;
        o) OUTPUT_DIR="${OPTARG}" ;;
		t) TIMEOUT_SECONDS="${OPTARG}" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

# Validate required arguments
if [ -z "$HASH_TYPE" ] || [ -z "$HASH_FILE" ]; then
    echo "Error: Hash type (-m) and hash file (-l) are required." >&2
    usage
    exit 1
fi

# Validate hash file exists
if [ ! -f "$HASH_FILE" ]; then
    echo "Error: Hash file '$HASH_FILE' not found." >&2
    exit 1
fi

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found." >&2
    exit 1
fi

# Set output directory
OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
OUTPUT_DIR="${OUTPUT_DIR%/}"  # Remove trailing slash if present

# Set Timeout duration
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-$DEFAULT_TIMEOUT_SECONDS}"

# Create output directories
echo "Creating output directories..."
mkdir -p "$OUTPUT_DIR"

# Check if the directory is empty
if [ -z "$(ls -A "$OUTPUT_DIR")" ]; then
    echo "✅ The directory '$OUTPUT_DIR' is empty, continuing..."
else
    echo "⚠️  The directory '$OUTPUT_DIR' is not empty."
    read -p "Do you want to clear it? (y/N) " answer
    case "$answer" in
        [yY]|[yY][eE][sS])
            echo "Deleting contents of '$OUTPUT_DIR'..."
            rm -rf "$OUTPUT_DIR"/* "$OUTPUT_DIR"/.[!.]* "$OUTPUT_DIR"/..?* 2>/dev/null
            echo "✅ Directory cleared."
            ;;
        *)
            echo "❌ The directory was not cleared, continuing..."
            ;;
    esac
fi

# Extract configuration using jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq to continue." >&2
    exit 1
fi

echo "Loading configuration from $CONFIG_FILE..."
readonly WORDLISTS=$(jq -r '.wordlists[]' "$CONFIG_FILE")
readonly RULES=$(jq -r '.rules[]' "$CONFIG_FILE")
readonly BRUTE_FORCE_LENGTHS=$(jq -r '.brute_force[]' "$CONFIG_FILE")

readonly HASHCAT_POTFILE_PATH=$(jq -r '.hashcat_potfile' "$CONFIG_FILE" | envsubst)

# Clear hashcat potfile to ensure clean results
echo "Clearing hashcat potfile..."
rm -f $HASHCAT_POTFILE_PATH 2>/dev/null


if [ -z "$WORDLISTS" ] && [ -z "$BRUTE_FORCE_LENGTHS" ]; then
    echo "Error: No wordlists or brute force configurations found in $CONFIG_FILE" >&2
    exit 1
fi

# Function to run hashcat attack
run_hashcat_attack() {
    local attack_cmd="$1"
    local output_file="$2"

    echo "Command: $attack_cmd"

    # Run hashcat with timeout and save output
    timeout --foreground "$TIMEOUT_SECONDS" hashcat -m $HASH_TYPE $HASH_FILE $attack_cmd \
        -O -w 3 \
        | tee "$output_file"

    local exit_code=$?
    if [ $exit_code -eq 124 ]; then
        echo "Attack timed out after $TIMEOUT_SECONDS seconds"
    elif [ $exit_code -ne 0 ]; then
        echo "Warning: Hashcat exited with code $exit_code"
    fi

    # Clear potfile for next attack
    rm -f $HASHCAT_POTFILE_PATH

    return 0
}

# Process wordlist + rule combinations
if [ -n "$WORDLISTS" ]; then
    echo ""
    echo "=== Starting Wordlist Attacks ==="
    echo ""

    total_combinations=$(($(echo "$WORDLISTS" | wc -l) * $(echo "$RULES" | wc -l)))
    current=0

    for wordlist in $WORDLISTS; do
        # Validate wordlist exists
        if [ ! -f "$wordlist" ]; then
            echo "Warning: Wordlist '$wordlist' not found, skipping..."
            continue
        fi

        wordlist_name=$(basename "$wordlist")

        for rule in $RULES; do
            # Validate rule file exists
            if [ ! -f "$rule" ]; then
                echo "Warning: Rule file '$rule' not found, skipping..."
                continue
            fi

            rule_name=$(basename "$rule")
            current=$((current + 1))

            echo ""
            echo "[$current/$total_combinations] Processing: $wordlist_name with $rule_name"
            echo "----------------------------------------"

            output_file="$OUTPUT_DIR/${wordlist_name}_${rule_name}"

            run_hashcat_attack \
                "$wordlist -r $rule" \
                "$output_file"
        done
    done
fi

# Process brute force attacks
if [ -n "$BRUTE_FORCE_LENGTHS" ]; then
    echo ""
    echo "=== Starting Brute Force Attacks ==="
    echo ""

    for length in $BRUTE_FORCE_LENGTHS; do
        echo ""
        echo "Brute force attack: $length characters"
        echo "----------------------------------------"

        # Generate mask for specified length
        mask="${DEFAULT_MASK:0:$((length * 2))}"
        output_file="$OUTPUT_DIR/bruteforce_${length}_chars"

        run_hashcat_attack \
            "-a 3 -1 ?l?d?u -2 ?l?d -3 3_default_mask_hashcat.hcchr $mask" \
            "$output_file"
    done
fi

# Run optimization algorithm
echo ""
echo "=== Running Optimization Algorithm ==="
echo ""

if [ -f "greedy_optimization.py" ]; then
    echo "Analyzing results to find attack sequence..."
    python3 greedy_optimization.py "$OUTPUT_DIR"

    if [ $? -eq 0 ]; then
        echo ""
        echo "Optimization complete!"
        echo "Results saved in: $OUTPUT_DIR/"
        echo "  - Sequence: $OUTPUT_DIR/cracking_sequence.txt"
        echo "  - Visualization: $OUTPUT_DIR/optimization_results.png"
    else
        echo "Warning: Greedy Optimization script failed"
    fi
else
    echo "Warning: greedy_optimization.py not found, skipping optimization"
fi

echo ""
echo "=== Processing Complete ==="
echo "All results saved in: $OUTPUT_DIR/"