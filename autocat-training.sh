#!/bin/bash

# Chemin vers le fichier JSON
config_file="config.json"
# total default mask hashcat
mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"


usage() {
  printf "Usage: ./autocat-training.sh -m <hashes_type> -l <hashes_location> [-o <output_files_path>] [-h]"
}

while getopts 'h:m:l:o:' opt; do
  case "${opt}" in
    m) hashes_type=${OPTARG} ;;
    l) hashes_location=${OPTARG} ;;
    o) output_files_path=${OPTARG} ;;
    h) usage
       exit 1 ;;
    *) usage
       exit 1 ;;
  esac
done

if [ -z "$hashes_type" ] || [ -z "$hashes_location" ]; then
        echo 'Incorrect arguments were passed.' >&2
        usage
        exit 1
fi

if [ -z "$output_files_path" ]; then
  echo 'Default location for the output files in ./result' >&2
  output_files_path="result"
fi

output_files_path=$(echo "$output_files_path" | sed 's/\/$//') # remove potential "/" at the end

if [ ! -d "$output_files_path" ]; then
    mkdir $output_files_path
fi

if [ ! -d "$output_files_path/hashcat_result" ]; then
  mkdir "$output_files_path/hashcat_result"
fi

rm ~/.local/share/hashcat/hashcat.potfile 2>/dev/null

# Utilisation de jq pour extraire les valeurs des tableaux
wordlists=$(jq -r '.wordlists[]' "$config_file")
rules=$(jq -r '.rules[]' "$config_file")
brute_force=$(jq -r '.brute_force[]' "$config_file")

for wordlist in $wordlists; do
  for rule in $rules; do
    echo "Élément : $wordlist $rule"
    name_wordlist=$(echo "$wordlist" | rev | cut -d'/' -f1 | rev)
    name_rule=$(echo "$rule" | rev | cut -d'/' -f1 | rev)
    echo "$output_files_path/$name_wordlist $name_rule"
    timeout --foreground 3600 hashcat -m $hashes_type $hashes_location $wordlist -r $rule --status --status-timer 1 --machine-readable -O -w 3| tee "$output_files_path/hashcat_result/$name_wordlist $name_rule"
    rm ~/.local/share/hashcat/hashcat.potfile 2>/dev/null
  done
done


for nb_digit in $brute_force; do
  echo "nb_digit : $nb_digit"
  mask="${mask_total:0:($nb_digit)*2}"
  echo "$output_files_path/$name_wordlist $name_rule"
  timeout --foreground 3600 hashcat $hashes_location -a 3 -1 ?l?d?u -2 ?l?d -3 3_default_mask_hashcat.hcchr $mask -m $hashes_type --status --status-timer 1 --machine-readable -O -w 3| tee "$output_files_path/hashcat_result/$nb_digit"
  rm ~/.local/share/hashcat/hashcat.potfile 2>/dev/null
done


python3 optimisation_locale.py $output_files_path