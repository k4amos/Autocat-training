#!/bin/bash

# Chemin vers le fichier JSON
config_file="config.json"
# total default mask hashcat
mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"


usage() {
  printf "Usage: ./autocat-training.sh -m <hashes_type> -l <hashes_location> [-o <output_files_path>] [-h]"
}

while getopts 'h:m:l:o' opt; do
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
  output_files_path="."
fi

rm ~/.local/share/hashcat/hashcat.potfile 2>/dev/null

# Utilisation de jq pour extraire les valeurs des tableaux
wordlists=$(jq -r '.wordlists[]' "$config_file")
rules=$(jq -r '.rules[]' "$config_file")
brute_force=$(jq -r '.brute_force[]' "$config_file")


for wordlist in $wordlists; do
  for rule in $rules; do
    echo "Élément : $wordlist $rule"
    name_wordlist = $(echo "$wordlist" | rev | cut -d'/' -f1 | rev)
    name_rule = $(echo "$rule" | rev | cut -d'/' -f1 | rev)
    echo $name_wordlist
    echo $name_rule
    timeout --foreground 3600 hashcat -m $hashes_type $hashes_location $wordlist -r $rule --status --status-timer 1 --machine-readable -O -w 3| tee "$output_files_path/$name_wordlist $name_rule"
    rm ~/.local/share/hashcat/hashcat.potfile 2>/dev/null
  done
done


for nb_digit in $brute_force; do
  echo "nb_digit : $nb_digit"
  mask="${mask_total:0:($nb_digit)*2}"
  timeout --foreground 3600 hashcat -a 3 -1 ?l?d?u -2 ?l?d -3 $mask 3_default_mask_hashcat.hcchr -m $hashes_type $hashes_location --status --status-timer 1 --machine-readable -O -w 3| tee "$output_files_path/$nb_digit"
  rm ~/.local/share/hashcat/hashcat.potfile 2>/dev/null
done




# methods_list=("fr-top20000 OneRuleToRuleThemAll.rule.log" "fr-top1000000 OneRuleToRuleThemAll.rule.log" "fr-top20000 rules.smart.log" "twitter clem9669_medium.rule.log" "fr-top1000000 rules.smart.log" "entreprise_fr OneRuleToRuleThemAll.rule.log" "pseudo OneRuleToRuleThemAll.rule.log" "fr-top1000000 rules.medium.log" "various_leak1 OneRuleToRuleThemAll.rule.log" "various_leak3 OneRuleToRuleThemAll.rule.log" "various_leak4 OneRuleToRuleThemAll.rule.log" "entreprise_fr rules.smart.log" "various_leak2 OneRuleToRuleThemAll.rule.log" "dictionnaire_fr rules.smart.log" "lastfm clem9669_medium.rule.log" "fr-top20000 clem9669_large.rule.log" "various_leak5 OneRuleToRuleThemAll.rule.log" "prenoms_fr rules.smart.log" "various_leak7 OneRuleToRuleThemAll.rule.log" "dictionnaire_en clem9669_large.rule.log" "entreprise_fr clem9669_medium.rule.log" "wikipedia_fr clem9669_medium.rule.log" "top_prenoms_combo OneRuleToRuleThemAll.rule.log" "breachcompilation.sorted clem9669_small.rule.log" "geo_wordlist_france rules.medium.log" "pseudo rules.smart.log" "wikifr clem9669_small.rule.log" "instagram rules.smart.log" "various_leak8 rules.medium.log" "sciences clem9669_large.rule.log" "brute_force_8.log" "villes_fr clem9669_large.rule.log" "keyboard_walk_fr OneRuleToRuleThemAll.rule.log" "various_leak1 rules.medium.log" "various_leak4 rules.smart.log" "domain_tld_FR OneRuleToRuleThemAll.rule.log" "news clem9669_large.rule.log" "compilation_prenoms clem9669_small.rule.log" "crackstation-human-only.txt OneRuleToRuleThemAll.rule.log" "fr-top1000000 clem9669_medium.rule.log" "expression clem9669_large.rule.log" "various_leak7 rules.smart.log" "wifi-ssid rules.medium.log" "various_leak5 rules.smart.log" "various_leak3 rules.smart.log" "pseudo rules.medium.log" "FB_FirstLast OneRuleToRuleThemAll.rule.log" "breachcompilation.sorted OneRuleToRuleThemAll.rule.log" "entreprise_fr clem9669_large.rule.log" "various_leak1 clem9669_medium.rule.log" "wikipedia_fr rules.smart.log" "date_ddmmyy_dot rules.medium.log" "various_leak7 rules.medium.log" "top_prenoms_combo rules.smart.log" "various_leak4 rules.medium.log" "various_leak5 clem9669_medium.rule.log" "twitter rules.medium.log" "various_leak2 rules.smart.log" "various_leak6 rules.small.log" "pseudo clem9669_medium.rule.log" "music rules.small.log" "keyboard_walk_us rules.small.log" "keyboard_walk_fr rules.smart.log" "dictionnaire_de rules.medium.log" "date_ddmmyyyy_slash rules.small.log" "date_ddmmyyyy_dot OneRuleToRuleThemAll.rule.log" "date_ddmmyy_dot clem9669_medium.rule.log" "adresses_fr clem9669_medium.rule.log" "wifi-ssid clem9669_large.rule.log" "various_leak3 clem9669_medium.rule.log" "various_leak5 rules.medium.log" "various_leak4 clem9669_medium.rule.log" "lastfm clem9669_large.rule.log" "various_leak2 rules.medium.log" "machine_names clem9669_large.rule.log" "wikifr OneRuleToRuleThemAll.rule.log" "noms_famille_fr rules.medium.log" "news rules.medium.log" "brands rules.smart.log" "various_leak2 clem9669_medium.rule.log" "wikipedia_fr clem9669_large.rule.log")
# mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"

# rm /home/tgirard/.local/share/hashcat/hashcat.potfile
# for i in "${methods_list[@]}"
# do
#    # rm /home/tgirard/.local/share/hashcat/hashcat.potfile
#     if [[ $i == *"brute_force"* ]] 
#     then
#         #echo "brute force" 
#         nb_digits=$(echo "$i" | grep -o '[0-9]')
#         mask="${mask_total:0:($nb_digits)*2}"
#         #echo "$mask"

#         #echo "$nb_digits"
#         timeout --foreground 3600 hashcat -m 1000 -a 3 -1 ?l?d?u -2 ?l?d -3 $mask 3_default.hcchr lyon_nt --status --status-timer 1 --machine-readable -O | tee "report_lyon_optimal/$i.log"
#     else
#         wordlist=$(echo "$i" | cut -d " " -f 1)
# 	rule_temp=$(echo "$i" | cut -d " " -f 2)
# 	rule="${rule_temp::-4}"
# 	if [ -f "/dico/$wordlist"]
#         then
#             timeout --foreground 3600 hashcat -m 1000 lyon_nt /dico/$wordlist -r /dico/rules/$rule --status --status-timer 1 --machine-readable -O | tee "report_lyon_optimal/$i $j.log"
#         else
#             timeout --foreground 3600 hashcat -m 1000 lyon_nt concat_all_ntds wordlists/$wordlist -r /dico/rules/$rule --status --status-timer 1 --machine-readable -O | tee "report_lyon_optimal/$i $j.log"
#         fi
#     fi
# done

#rm /home/tgirard/.local/share/hashcat/hashcat.potfile
