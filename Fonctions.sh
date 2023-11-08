#!/bin/bash

# Fonction affichant la valeur de la cellule dans la feuille
# Paramètres : Feuille, Numéro de Ligne, Numéro de Colonne
function cellule() {
  local row=$(echo -e "$1" | head -n $2 | tail -n 1)
  echo -e "$row" | cut -f $3
}

# Fonction affichant l'addition de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function additionne() {
  echo "$1 + $2" | bc -l
}

# Fonction affichant la soustraction de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function soustrait() {
  echo "$1 - $2" | bc -l
}

# Fonction affichant la multiplication de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function multiplie() {
  echo "$1 * $2" | bc -l
}

# Fonction affichant la division de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function divise() {
  if test $(echo $2 | cut -d '.' -f 1) -eq 0 && test $(echo $2 | cut -d '.' -f 2) -eq 0; then
    echo "Division par zéro" && exit 1
  fi
  echo "$1 / $2" | bc -l
}

# Fonction affichant le resultat de val1 puissance val2
# Paramètres : Nombre 1, Nombre 2
function puissance() {
  echo "$1 ^ $2" | bc -l
}

# Fonction affichant le logarihme népérien de val1
# Paramètres : Nombre 1
function logarithme() {
  if test $(echo $1 | cut -d '.' -f 1) -le 0; then
    echo "Logarithme d'un nombre négatif" && exit 2
  fi
  echo "l($1)" | bc -l
}

# Fonction affichant l'exponentiation de e à la puissance val1
# Paramètres : Nombre 1
function exponentielle() {
  echo "e($1)" | bc -l
}

# Fonction affichant l'exponentiation de e à la puissance val1
# Paramètres : Nombre 1
function racine() {
  if test $(echo $1 | cut -d '.' -f 1) -lt 0; then
    echo "Racine d'un nombre négatif" && exit 3
  fi
  echo "sqrt($1)" | bc -l
}

###################################################################

# Fonction permettant d'avoir la ligne et la colonne d'une notation licj de cellule
# Paramètre : Chaine contenant la notation licj
function ligne_colonne() {
  echo "$1" | sed 's/l//' | sed 's/c/ /'
}

# Fonction permettant de remplacer le contenu d'une cellule par un autre
# Paramètres : Feuille, Numéro de Ligne, Numéro de Colonne, Le nouveau contenu
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
    echo -e "\nProblème de parenthésage" && exit 4
  fi
  echo " $chaine" # On affiche le deuxième paramètre
}

# Fonction permettant de traiter une cellule de la feuille recursivement
# Elle retourne une nouvelle feuille avec la cellule mise à jour
# Paramètres : Feuille, Numéro de Ligne, Numéro de Colonne
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

# Fonction permettant d'executer et de faire le calcul d'une fonction
# Elle retourne la feuille mis à jour suivi du resultat du calcul
# Paramètres : Feuille, La chaine de la fonction
function execute_fonction() {
  local calcul fonc param1 param2 res nblig nouv_feuille=$1
  # On sépare le nom de la fonction et ses paramètres
  calcul="$(nom_parametres "$2")"
  fonc=$(echo "$calcul" | cut -d ' ' -f 1)   # nom de la fonction
  param1=$(echo "$calcul" | cut -d ' ' -f 2) # Premier paramètre
  param2=$(echo "$calcul" | cut -d ' ' -f 3) # Deuxième paramètre

  # Si le premier paramètre est une fonction, on l'execute et on garde la valeur
  if test $(expr index "$param1" "\([") -ne 0; then
    nblig=$(echo -e "$1" | wc -l)
    res="$(execute_fonction "$nouv_feuille" "$param1")"
    nouv_feuille=$(echo -e "$res" | head -n $nblig)
    param1=$(echo -e "$res" | tail -n +$((nblig + 1)))
  # Si non si il est au format licj, il traite la cellule et garde la valeur
  elif test $(expr "$param1" : 'l[0-9]\+c[0-9]\+') -ne 0; then
    nouv_feuille="$(Traite_cellule "$nouv_feuille" $(ligne_colonne "$param1"))"
    param1=$(cellule "$nouv_feuille" $(ligne_colonne "$param1"))
  fi

  # On fait la même chose pour la deuxième paramètre
  if test $(expr index "$param2" "\([") -ne 0; then
    nblig=$(echo -e "$1" | wc -l)
    res="$(execute_fonction "$nouv_feuille" "$param2")"
    nouv_feuille=$(echo -e "$res" | head -n $nblig)
    param2=$(echo -e "$res" | tail -n +$((nblig + 1)))
  elif test $(expr "$param2" : 'l[0-9]\+c[0-9]\+') -ne 0; then
    nouv_feuille="$(Traite_cellule "$nouv_feuille" $(ligne_colonne "$param2"))"
    param2=$(cellule "$nouv_feuille" $(ligne_colonne "$param2"))
  fi

  # On applique la fonction approprié en fonction de $fonc
  case $fonc in
  "+")
    res=$(additionne $param1 $param2)
    ;;
  "-")
    res=$(soustrait $param1 $param2)
    ;;
  "*")
    res=$(multiplie $param1 $param2)
    ;;
  "/")
    res=$(divise $param1 $param2)
    ;;
  "^")
    res=$(puissance $param1 $param2)
    ;;
  "ln")
    res=$(logarithme $param1)
    ;;
  "e")
    res=$(exponentielle $param1)
    ;;
  "sqrt")
    res=$(racine $param1)
    ;;
  "cellule")
    res="$param1"
    ;;
  *)
    echo "$fonc ne correspond à aucune fonction !"
    exit 5
    ;;
  esac

  # On retourne la nouvelle feuille et le resultat
  echo "$nouv_feuille"
  echo "$res"
}

Traite_cellule "$1" 3 4
