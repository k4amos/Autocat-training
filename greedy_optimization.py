#!/usr/bin/env python3
"""
Greedy optimization algorithm for password cracking sequence optimization.
"""

import plotly.graph_objects as go
import os
import sys
from typing import Dict, Set, List, Tuple, Optional
from datetime import datetime


def parse_hashcat_output(filepath: str) -> Tuple[Set[str], int]:
    """
    Parse hashcat output file to extract recovered passwords and execution time.

    Args:
        filepath: Path to the hashcat output file

    Returns:
        Tuple containing set of recovered passwords and time in seconds
    """

    recovered_passwords = []
    fmt = "%a %b %d %H:%M:%S %Y"
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.count(":")  == 1 and " " not in line.split(":")[1] and line.split(":")[1] != "\n":
                    try:
                        recovered_passwords.append(line.split(":")[1])
                    except Exception as e:
                        print(e)

            elif line.startswith("Started: "):
                start_time = datetime.strptime(line.split("Started: ")[1], fmt)

            elif line.startswith("Stopped: "):
                stop_time  = datetime.strptime(line.split("Stopped: ")[1], fmt)

        delta_seconds = (stop_time - start_time).total_seconds()
    return set(recovered_passwords), delta_seconds


def load_attack_results(output_path: str) -> Dict[str, Dict]:
    """
    Load all attack results from hashcat output directory.

    Args:
        output_path: Path to the output directory

    Returns:
        Dictionary with attack names as keys and their results as values
    """
    results_dir = f"{output_path}/"
    files = os.listdir(results_dir)

    attack_results = {}

    for filename in files:
        try:
            passwords, time_spent = parse_hashcat_output(f"{results_dir}/{filename}")

            if len(passwords) > 0:
                display_name = filename

                attack_results[display_name] = {
                    "passwords": passwords,
                    "time": time_spent
                }
        except Exception as e:
            print(f"Warning: Could not process file {filename}: {e}")
            continue

    return attack_results


def calculate_efficiency(attacks: Dict[str, Dict], recovered_passwords: Set[str]) -> Optional[str]:
    """
    Find the most efficient attack based on password recovery rate.

    Args:
        attacks: Dictionary of available attacks
        recovered_passwords: Set of already recovered passwords

    Returns:
        Name of the most efficient attack or None if no attacks available
    """
    if not attacks:
        return None

    efficiencies = []
    attack_names = []

    for name, data in attacks.items():
        # Calculate new passwords this attack would recover
        new_passwords = data["passwords"] - recovered_passwords
        # Avoid division by zero
        if data["time"] > 0:
            efficiency = len(new_passwords) / data["time"]
        else:
            efficiency = 0

        efficiencies.append(efficiency)
        attack_names.append(name)

    if not efficiencies:
        return None

    # Sort by efficiency and return the best one
    sorted_attacks = sorted(zip(efficiencies, attack_names), reverse=True)
    return sorted_attacks[0][1] if sorted_attacks else None


def update_remaining_attacks(attacks: Dict[str, Dict], recovered_passwords: Set[str]) -> Dict[str, Dict]:
    """
    Update attack results by removing already recovered passwords.

    Args:
        attacks: Dictionary of attacks to update
        recovered_passwords: Set of already recovered passwords

    Returns:
        Updated attacks dictionary
    """
    for name in attacks:
        attacks[name]["passwords"] = attacks[name]["passwords"] - recovered_passwords
    return attacks


def optimize_cracking_sequence(attacks: Dict[str, Dict], time_limit: int = 36000) -> List[str]:
    """
    Find sequence of attacks within time limit using greedy optimization.

    Args:
        attacks: Dictionary of available attacks
        time_limit: Maximum time budget in seconds (default: 10 hours)

    Returns:
        Ordered list of attack names representing sequence
    """
    fig = go.Figure()
    total_time = 0
    sequence = []
    recovered_passwords = set()
    remaining_attacks = attacks.copy()

    while total_time < time_limit:
        # Find the most efficient attack
        best_attack = calculate_efficiency(remaining_attacks, recovered_passwords)

        if best_attack is None:
            print("No more attacks available")
            break

        # Check if this attack would recover any new passwords
        new_passwords = remaining_attacks[best_attack]["passwords"] - recovered_passwords
        if len(new_passwords) == 0:
            print(f"Attack '{best_attack}' would not recover new passwords, skipping")
            del remaining_attacks[best_attack]
            continue

        # Check if we have enough time remaining
        attack_time = remaining_attacks[best_attack]["time"]
        if total_time + attack_time > time_limit:
            print(f"Not enough time for '{best_attack}' (needs {attack_time}s, have {time_limit - total_time}s)")
            del remaining_attacks[best_attack]
            continue

        print(f"Selected attack: {best_attack}")
        sequence.append(best_attack)

        fig.add_trace(go.Scatter(
            x=[total_time, total_time + remaining_attacks[best_attack]["time"]],
            y=[len(recovered_passwords), len(recovered_passwords | remaining_attacks[best_attack]["passwords"])],
            mode='markers+lines',
            name=best_attack
        ))

        total_time += attack_time
        recovered_passwords = recovered_passwords | remaining_attacks[best_attack]["passwords"]

        # Update remaining attacks
        remaining_attacks = update_remaining_attacks(remaining_attacks, recovered_passwords)
        del remaining_attacks[best_attack]

    # Configure and display plot
    fig.update_layout(
        title={
            'text': 'Password Cracking Sequence',
            'y': 0.9,
            'x': 0.5,
            'xanchor': 'center',
            'yanchor': 'top'
        },
        xaxis_title="Time (seconds)",
        yaxis_title="Cumulative Recovered Passwords",
        showlegend=True,
        hovermode='x unified'
    )

    return fig, sequence


def main():
    """Main entry point for the optimization script."""
    if len(sys.argv) < 2:
        print("Usage: python3 attack_sequence_optimizer.py <output_directory>")
        sys.exit(1)

    output_path = sys.argv[1]

    # Load all attack results
    print(f"Loading attack results from {output_path}/")
    attacks = load_attack_results(output_path)
    print(f"Loaded {len(attacks)} successful attacks")

    if not attacks:
        print("No successful attacks found. Exiting.")
        sys.exit(1)

    # Run optimization
    print("\nRunning optimization algorithm...")
    fig, sequence = optimize_cracking_sequence(attacks)

    # Display and save results
    fig.write_image(f"{output_path}/optimization_results.png")

    # Save sequence to file
    with open(f"{output_path}/cracking_sequence.txt", "w") as f:
        f.write("Attack Sequence:\n")
        f.write("=" * 50 + "\n")
        for i, attack in enumerate(sequence, 1):
            f.write(f"{i}. {attack}\n")

    print(f"\nSequence saved to {output_path}/cracking_sequence.txt")
    print(f"Visualization saved to {output_path}/optimization_results.png")

    return sequence


if __name__ == "__main__":
    sequence = main()
    print("\nAttack sequence:")
    for i, attack in enumerate(sequence, 1):
        print(f"  {i}. {attack}")