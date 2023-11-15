#!/bin/bash

# Traitement des fonctions de bases du projet
source bases.sh
# Traitement des fonctions utilitaires du projet
source utilitaires.sh

##### Programme principale #####

# Calcul du nombre de lignes et du nombre de colonnes
nblig=$(echo -e "$1" | wc -l)
nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)

Traite_intervalle_cellule "$1" 1 1 $nblig $nbcol