#!/bin/bash

# Fonction permettant d'avoir la ligne et la colonne d'une notation licj de cellule
# Paramètre : Chaine contenant la notation licj
function ligne_colonne() {
  echo "$1" | sed 's/l//' | sed 's/c/ /'
}

# Fonction permettant de voir si la ligne et la colonne d'une cellule est valide
# Paramètre : Feuille, Ligne, Colonne
function valide_ligcol() {
  local nblig nbcol
  nblig=$(echo -e "$1" | wc -l)
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  test $2 -le $nblig && test $3 -le $nbcol
}

# Fonction permettant de remplacer le contenu d'une cellule par un autre
# Paramètres : Feuille, Ligne, Colonne, Le nouveau contenu
function remplace_cellule() {
  local row new_row
  row=$(echo -e "$1" | head -n $2 | tail -n 1)
  new_row=$(echo "$row" | sed -E "s/(^([^\t]+\t){$(expr $3 - 1)})[^\t]+/\1$4/")
  echo -e "$1" | head -n $(expr $2 - 1)
  echo -e "$new_row"
  echo -e "$1" | tail -n +$(expr $2 + 1)
}

# Fonction permettant d'avoir le nom et les 2 paramètres d'une fonction
# Utilise le nombre de parenthèses ouvertes et fermées pour distinguer les paramètres
# Paramètres : Chaine de Fonction
function nom_parametres() {
  # Si ça commence par un crochet, on traite le cas de [cel]
  if test $(expr substr "$1" 1 1) = '['; then
    echo "cellule $(echo "$1" | egrep -o 'l[0-9]+c[0-9]+')"
    return
  fi
  # Si non
  local chaine params ouv=0

  # On affiche le nom de la fonction
  echo -n $(echo $1 | cut -d '(' -f 1)

  # On s'intéresse qu'aux paramètre seulement et on les parcours caractère par caractère
  params="$(echo $1 | sed -E "s/(^[^(]+\(|\)$)//g")"
  for car in $(echo "$params" | sed 's/./& /g'); do
    if test "$car" = '('; then
      ouv=$((ouv + 1)) # on ajoute 1 au compteur de parenthèse
      chaine="${chaine}${car}"
    elif test "$car" = ')'; then
      ouv=$((ouv - 1)) # On diminue 1 au compteur de parenthèse
      chaine="${chaine}${car}"
    # Si on voit une virgule et que notre compteur est nul, on affiche le premier paramètre
    elif test "$car" = ',' && test $ouv -eq 0; then
      echo -n " $chaine"
      chaine=""
    else
      chaine="${chaine}${car}"
    fi
  done
  if test $ouv -ne 0; then
    echo -e "\nProblème de parenthésage" && exit 100
  fi
  echo " $chaine" # On affiche le deuxième paramètre
}

# Fonction permettant de traiter une cellule de la feuille recursivement
# Elle retourne une nouvelle feuille avec la cellule mise à jour
# Paramètres : Feuille, Ligne, Colonne
function Traite_cellule() {
  # On récupère la cellule
  local calcul="$(cellule "$1" $2 $3)"

  # Si le contenu commence pas par un '=', il renvoie la feuille
  if test $(expr substr "$calcul" 1 1) != '='; then
    echo "$1"
    return
  fi
  # Si non, cela veut dire que c'est un calcul
  local nouv_feuille nblig res
  # on enlève l'égal du calcul
  calcul=$(echo "$calcul" | sed 's/=//')
  nblig=$(echo -e "$1" | wc -l)

  # On execute le calcul de la fonction tout en recuperant le resultat et la feuille
  res="$(execute_fonction "$1" "$calcul")"
  nouv_feuille=$(echo -e "$res" | head -n $nblig)
  res=$(echo -e "$res" | tail -n +$((nblig + 1)))

  # On remplace le resultat dans la nouvelle feuille
  remplace_cellule "$nouv_feuille" $2 $3 "$res"
}

# Fonction permettant de faire le traitement de tous les cellules entre ceux passées en paramètre
# Elle retourne la feuille avec toutes les cellules mises à jour
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function Traite_intervalle_cellule() {
  local lig col nbcol nouv_feuille="$1"
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    nouv_feuille="$(Traite_cellule "$nouv_feuille" $lig $col)"
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  nouv_feuille="$(Traite_cellule "$nouv_feuille" $lig $col)"
  echo -e "$nouv_feuille"
}

# Fonction permettant d'executer et de faire le calcul d'une fonction
# Elle retourne la feuille mis à jour suivi du resultat du calcul
# Paramètres : Feuille, La chaine de la fonction
function execute_fonction() {
  local calcul fonc param1 param2 val1 val2 res nblig nouv_feuille="$1"
  # On sépare le nom de la fonction et ses paramètres
  calcul="$(nom_parametres "$2")"
  fonc=$(echo "$calcul" | cut -d ' ' -f 1)   # nom de la fonction
  param1=$(echo "$calcul" | cut -d ' ' -f 2) # Premier paramètre
  param2=$(echo "$calcul" | cut -d ' ' -f 3) # Deuxième paramètre

  # Si le premier paramètre est une fonction, on l'execute et on garde la valeur
  if test $(expr index "$param1" "\([") -ne 0; then
    nblig=$(echo -e "$1" | wc -l)
    res="$(execute_fonction "$nouv_feuille" "$param1")"
    nouv_feuille="$(echo -e "$res" | head -n $nblig)"
    param1="$(echo -e "$res" | tail -n +$((nblig + 1)))"
  fi
  # si il est au format licj, on traite la cellule et on garde la valeur
  if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -ne 0; then
    if ! valide_ligcol "$nouv_feuille" $(ligne_colonne $param1); then
      echo "Invalide accès à la feuille"
      exit 101
    fi
    nouv_feuille="$(Traite_cellule "$nouv_feuille" $(ligne_colonne "$param1"))"
    val1="$(cellule "$nouv_feuille" $(ligne_colonne "$param1"))"
  else
    val1="$param1"
  fi

  # On fait la même chose pour la deuxième paramètre
  if test $(expr index "$param2" "\([") -ne 0; then
    nblig=$(echo -e "$1" | wc -l)
    res="$(execute_fonction "$nouv_feuille" "$param2")"
    nouv_feuille="$(echo -e "$res" | head -n $nblig)"
    param2="$(echo -e "$res" | tail -n +$((nblig + 1)))"
  fi
  if test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -ne 0; then
    if ! valide_ligcol "$nouv_feuille" $(ligne_colonne $param2); then
      echo "Invalide accès à la feuille"
      exit 101
    fi
    nouv_feuille="$(Traite_cellule "$nouv_feuille" $(ligne_colonne "$param2"))"
    val2="$(cellule "$nouv_feuille" $(ligne_colonne "$param2"))"
  else
    val2="$param2"
  fi

  # On applique la fonction approprié en fonction de $fonc
  case $fonc in
  "cellule")
    res="$val1"
    ;;
  "+")
    res=$(additionne $val1 $val2)
    ;;
  "-")
    res=$(soustrait $val1 $val2)
    ;;
  "*")
    res=$(multiplie $val1 $val2)
    ;;
  "/")
    res=$(divise $val1 $val2)
    ;;
  "^")
    res=$(puissance $val1 $val2)
    ;;
  "ln")
    res=$(logarithme $val1)
    ;;
  "e")
    res=$(exponentielle $val1)
    ;;
  "sqrt")
    res=$(racine $val1)
    ;;
  "somme")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(somme "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  "moyenne")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(moyenne "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  "variance")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(variance "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  "ecartype")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(ecartype "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  "mediane")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(mediane "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  "min")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(minimum "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  "max")
    nouv_feuille=$(Traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    res=$(maximum "$nouv_feuille" $(ligne_colonne $param1) $(ligne_colonne $param2))
    ;;
  *)
    echo "$fonc ne correspond à aucune fonction !"
    exit 102
    ;;
  esac

  # On retourne la nouvelle feuille et le resultat
  echo "$nouv_feuille"
  echo "$res"
}