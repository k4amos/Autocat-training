import plotly.graph_objects as go
import os
import sys

list_time_x = []
list_time_y = []

output_files_path = sys.argv[1]

list_file = os.listdir(output_files_path)

limite_seconde = 3600

limite_seconde_algo = 3600

def create_set(filename, nombre_seconde_limite):
    with open(f"{output_files_path}/{filename}", "r") as f:
            all_lines = f.readlines()

    list_mdp = []
    compteur_seconde = 0
    for k in range(len(all_lines)):
        if ":" in all_lines[k] and " " not in all_lines[k].split(":")[1] and all_lines[k].split(":")[1] != "\n":
           list_mdp.append(all_lines[k].split(":")[1])
        if "STATUS" in all_lines[k]:
            compteur_seconde +=1
        if compteur_seconde > nombre_seconde_limite:
            return list_mdp, compteur_seconde
    return list_mdp, compteur_seconde


ensemble_objets = {}
for filename in list_file:
    try:
        list_mdp, compteur_seconde = create_set(filename, limite_seconde)
        if len(set(list_mdp)) != 0:
            ensemble_objets[filename] = {"ensemble":set(list_mdp), "poids":compteur_seconde}
    except:
        pass

def get_best_element(sous_ensemble_objets, total_mdp):
    vitesse_sous_ensemble_objets = []
    for name in [*sous_ensemble_objets]:
        vitesse_sous_ensemble_objets.append(len(sous_ensemble_objets[name]["ensemble"])/sous_ensemble_objets[name]["poids"])

    vitesse_sous_ensemble_objets_trie, sous_ensemble_objets_trie,  = zip(*sorted(zip(vitesse_sous_ensemble_objets, [*sous_ensemble_objets]), reverse=True))

    return sous_ensemble_objets_trie[0]


def create_sous_ensemble_objets(name_set_retenu, sous_ensemble_objets, total_mdp):
    for name in [*sous_ensemble_objets]:
        sous_ensemble_objets[name]["ensemble"] = sous_ensemble_objets[name]["ensemble"] - total_mdp
    return sous_ensemble_objets


def solver_local_optimisation(sous_ensemble_objets):
    fig = go.Figure()
    total_seconde = 0
    liste_ordre = []
    total_mdp = set()
    #meilleur_element = get_best_element(sous_ensemble_objets, total_mdp)
    while total_seconde < limite_seconde_algo:
        meilleur_element = get_best_element(sous_ensemble_objets, total_mdp)
        liste_ordre.append(meilleur_element)

        fig.add_trace(go.Scatter(
            x=[total_seconde, total_seconde+sous_ensemble_objets[meilleur_element]["poids"]], 
            y=[len(total_mdp), len(total_mdp | sous_ensemble_objets[meilleur_element]["ensemble"])],
            mode='markers+lines',
            name=meilleur_element)
        )

        if len(total_mdp | sous_ensemble_objets[meilleur_element]["ensemble"]) == len(total_mdp):
            break

        total_mdp = total_mdp | sous_ensemble_objets[meilleur_element]["ensemble"]

        total_seconde += sous_ensemble_objets[meilleur_element]["poids"]

        sous_ensemble_objets = create_sous_ensemble_objets(meilleur_element, sous_ensemble_objets, total_mdp)

        
    fig.update_layout(
        title={
            'text': "Mots de passe cassés au cours du temps sur les hashs d'entrainement",
            'y':0.9,
            'x':0.5,
            'xanchor': 'center',
            'yanchor': 'top'
        },
        xaxis_title="temps (s)",
        yaxis_title="Mots de passe cassés",
        
        )

    fig.show()

    return liste_ordre


liste_ordre = solver_local_optimisation(ensemble_objets)

print(liste_ordre)


