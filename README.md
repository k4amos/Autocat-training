# Autocat Training

<p align="center">
    <img src="img/logo.png" style="height:350px">
</p>

## Overview

Autocat-training aims to solve the **knapsack problem** using a **greedy algorithm** to determine the most optimal password cracking sequence for cracking a given input list of hashes.

This can enable benchmarking with a large number of hashes from diverse sources to determine a generic cracking sequence that effectively cracks hashes from a specific language or geographic region.

⚠️ **The README is currently under construction.**

```

## Usage

### Basic Command

```bash
./autocat-training.sh -m <hash_type> -l <hash_file> [-o <output_dir>]
```

### Parameters

- `-m <hash_type>`: Hashcat hash type number (required)
  - Example: `0` for MD5, `1000` for NTLM, `1800` for SHA-512 Unix
- `-l <hash_file>`: Path to file containing hashes to crack (required)
- `-o <output_dir>`: Output directory for results (optional, default: `./results`)
- `-h`: Display help message

### Examples

```bash
# Crack NTLM hashes
./autocat-training.sh -m 1000 -l ntlm_hashes.txt

# Crack MD5 hashes with custom output directory
./autocat-training.sh -m 0 -l md5_hashes.txt -o my_audit_results

# Display help
./autocat-training.sh -h
```

## Configuration

The tool uses a `config.json` file to define attack strategies. The configuration includes:

### Wordlists

Array of wordlist file paths to use for dictionary attacks:

```json
"wordlists": [
    "/usr/share/wordlists/autocat/wordlists/default_password",
    "/usr/share/wordlists/autocat/wordlists/keyboard_walk_us",
    ...
]
```

### Rules

Array of rule files for password mutations:

```json
"rules": [
    "/usr/share/wordlists/autocat/rules/best64.rule",
    "/usr/share/wordlists/autocat/rules/dive.rule",
    ...
]
```

### Brute Force

Array of character lengths for brute force attacks:

```json
"brute_force": [4, 5, 6, 7, 8, 9, 10]
```

## How It Works

### 1. Attack Execution Phase

The tool systematically executes:
- **Wordlist + Rule Combinations**: Each wordlist is combined with each rule file
- **Brute Force Attacks**: Incremental mask attacks for specified character lengths

Each attack runs with:
- 1-hour timeout (configurable)
- Machine-readable output for parsing
- Status updates every second
- Optimized performance settings (-O -w 3)

### 2. Optimization Phase

After collecting results, the optimization algorithm:

1. **Parses Results**: Extracts recovered passwords and execution time from each attack
2. **Calculates Efficiency**: Computes passwords/second recovery rate for each attack
3. **Greedy Selection**: Iteratively selects the most efficient remaining attack
4. **Generates Sequence**: Produces an ordered list of attacks optimized for time efficiency
5. **Creates Visualization**: Plots cumulative password recovery over time

### 3. Output Files

The tool generates several output files in the specified directory:

```
results/
├── hashcat_result/          # Raw hashcat output for each attack
│   ├── wordlist1_rule1      # Individual attack results
│   ├── wordlist2_rule1
│   └── bruteforce_6chars
├── cracking_sequence.txt  # Recommended attack order
└── optimization_results.png       # Visualization of recovery rates
```

## Mask Configuration

The tool includes a custom character set file (`3_default_mask_hashcat.hcchr`) that defines:
- Lowercase letters (a-z)
- Numbers (0-9)
- Special characters (*!$@_)

This is used for brute force attacks with the mask pattern: `?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d`

## Security Considerations

⚠️ **Important**: This tool is designed for legitimate security testing only.

- Only use on systems you own or have explicit permission to test
- Store hash files securely and delete after testing
- Be aware of legal implications in your jurisdiction
- Consider computational resources and electricity costs
- Implement proper access controls on result files

## Performance Tips

1. **Optimize Wordlists**: Start with targeted wordlists relevant to your context
2. **Rule Selection**: Use proven rule sets like OneRuleToRuleThemAll
3. **Hardware Acceleration**: Ensure GPU drivers are properly configured
4. **Time Limits**: Adjust timeout based on your testing window
5. **Incremental Testing**: Start with shorter brute force lengths

## Troubleshooting

### Common Issues

1. **"hashcat: command not found"**
   - Ensure hashcat is installed and in PATH

2. **"jq: command not found"**
   - Install jq package for JSON processing

3. **Python module errors**
   - Install required packages: `pip install plotly kaleido`

4. **Permission denied**
   - Make script executable: `chmod +x autocat-training.sh`

5. **No results generated**
   - Check hash format matches specified type
   - Verify wordlists and rules exist at specified paths

## Advanced Usage

### Custom Attack Strategies

Modify `config.json` to customize attack strategies:

```json
{
    "wordlists": ["custom_wordlist.txt"],
    "rules": ["custom_rules.rule"],
    "brute_force": [4, 5, 6]
}
```

### Integration with Other Tools

Results can be integrated with:
- Security reporting tools
- Password policy analyzers
- Compliance verification systems

## Project Structure

```
autocat-training/
├── autocat-training.sh           # Main execution script
├── attack_sequence_optimizer.py         # Optimization algorithm
├── config.json                   # Attack configuration
├── 3_default_mask_hashcat.hcchr # Character set for brute force
├── LICENSE                       # License information
├── README.md                     # This file
└── img/
    └── logo.png                  # Project logo
```

## License

This project is licensed under the terms specified in the LICENSE file.

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing style conventions
- Documentation is updated for new features
- Security best practices are maintained

## Disclaimer

This tool is provided for educational and authorized security testing purposes only. Users are responsible for complying with all applicable laws and regulations. The authors assume no liability for misuse or damage caused by this tool.

## Acknowledgments

- [Autocat](https://github.com/k4amos/Autocat) - The parent project this tool supports
- Hashcat team for the powerful password recovery engine
- Security research community for rule sets and wordlists
- Open source contributors