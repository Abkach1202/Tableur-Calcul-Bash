#!/bin/bash

# Fonction affichant la valeur de la cellule dans la feuille
# Paramètres : Feuille, Numéro de Ligne, Numéro de Colonne
function cellule() {
  local row res
  row=$(echo -e "$1" | head -n $2 | tail -n 1)
  res=$(echo -e "$row" | cut -f $3)
  echo $res
}

# Fonction affichant l'addition de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function additionne() {
  local res
  res=$(echo "$1 + $2" | bc -l)
  echo $res
}

# Fonction affichant la soustraction de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function soustrait() {
  local res
  res=$(echo "$1 - $2" | bc -l)
  echo $res
}

# Fonction affichant la multiplication de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function multiplie() {
  local res
  res=$(echo "$1 * $2" | bc -l)
  echo $res
}

# Fonction affichant la division de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function divise() {
  local res
  if test $2 -eq 0; then
    echo "Division par zéro" && exit 1
  fi
  res=$(echo "$1 / $2" | bc -l)
  echo $res
}

# Fonction affichant le resultat de val1 puissance val2
# Paramètres : Nombre 1, Nombre 2
function puissance() {
  local res
  res=$(echo "$1 ^ $2" | bc -l)
  echo $res
}

# Fonction affichant le logarihme népérien de val1
# Paramètres : Nombre 1
function logarithme() {
  local res
  if test $1 -le 0; then
    echo "Logarithme d'un nombre négatif" && exit 2
  fi
  res=$(echo "l($1)" | bc -l)
  echo $res
}

# Fonction affichant l'exponentiation de e à la puissance val1
# Paramètres : Nombre 1
function exponentielle() {
  local res
  res=$(echo "e($1)" | bc -l)
  echo $res
}

# Fonction affichant l'exponentiation de e à la puissance val1
# Paramètres : Nombre 1
function racine() {
  local res
  if test $1 -lt 0; then
    echo "Racine d'un nombre négatif" && exit 3
  fi
  res=$(echo "sqrt($1)" | bc -l)
  echo $res
}

###################################################################

# Fonction permettant d'avoir le nom et les 2 paramètres d'une fonction
# Paramètres : Chaine de Fonction
function nom_parametres() {
  local chaine params ouv=0
  echo -n $(echo $1 | cut -d '(' -f 1)
  params=$(echo $1 | sed -E "s/(^[^(]+\(|\)$)//g")
  for car in $(echo "$params" | sed 's/./& /g'); do
    if test "$car" = '('; then
      ouv=$((ouv + 1))
      chaine="${chaine}${car}"
    elif test "$car" = ')'; then
      ouv=$((ouv - 1))
      chaine="${chaine}${car}"
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
  echo " $chaine"
}

nom_parametres "$1"
