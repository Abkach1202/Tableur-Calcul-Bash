#!/bin/bash

# Fonction affichant la valeur de la cellule dans la feuille
# Paramètres : Feuille, Ligne, Colonne
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

# Fonction affichant la racine de val1
# Paramètres : Nombre 1
function racine() {
  if test $(echo $1 | cut -d '.' -f 1) -lt 0; then
    echo "Racine d'un nombre négatif" && exit 3
  fi
  echo "sqrt($1)" | bc -l
}

# Fonction permettant de calculer la somme à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function somme() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "mauvaise écriture des paramètres de somme !" && exit 4
  fi
  local lig col nbcol som=0
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    som=$(additionne $som $(cellule "$1" $lig $col))
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  som=$(additionne $som $(cellule "$1" $lig $col))
  echo $som
}

# Fonction permettant de faire la moyenne à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function moyenne() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "mauvaise écriture des paramètres de somme !" && exit 4
  fi
  local nbcol nbcel som
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  som=$(somme "$1" $2 $3 $4 $5)
  nbcel=$(echo "(1 + $nbcol - $3) + (($4 - $2) * $nbcol) - ($nbcol - $5)" | bc -l)
  echo "$som / $nbcel" | bc -l
}

# Fonction permettant de calculer la moyenne à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function variance() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "mauvaise écriture des paramètres de somme !" && exit 4
  fi
  local lig col nbcol nbcel moy som=0
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  moy=$(moyenne "$1" $2 $3 $4 $5)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    som=$(echo "$som + ($(cellule "$1" $lig $col) - $moy) ^ 2" | bc -l)
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  som=$(echo "$som + ($(cellule "$1" $lig $col) - $moy) ^ 2" | bc -l)
  nbcel=$(echo "(1 + $nbcol - $3) + (($4 - $2) * $nbcol) - ($nbcol - $5)" | bc -l)
  echo "$som / $nbcel" | bc -l
}

# Fonction permettant de calculer l'écartype à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function ecartype() {
  racine $(variance "$1" $2 $3 $4 $5)
}

# Fonction permettant de calculer la médiane à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function mediane() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "mauvaise écriture des paramètres de somme !" && exit 4
  fi
  local lig col nbcol nbcel data=""
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    data="$data$(cellule "$1" $lig $col)\n"
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  data="$data$(cellule "$1" $lig $col)"
  nbcel=$(echo "(1 + $nbcol - $3) + (($4 - $2) * $nbcol) - ($nbcol - $5)" | bc -l)
  echo -e "$data" | sort -n | head -n $(((nbcel + 1) / 2)) | tail -n 1
}

# Fonction permettant d'avoir le minimum à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function minimum() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "mauvaise écriture des paramètres de somme !" && exit 4
  fi
  local lig col nbcol min
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  min=$(cellule "$1" $4 $5)
  while test $lig -ne $4 || test $col -ne $5; do
    if test $(echo "$(cellule "$1" $lig $col) < $min" | bc) -eq 1; then
      min=$(cellule "$1" $lig $col)
    fi
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  echo $min
}

# Fonction permettant d'avoir le minimum à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function maximum() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "mauvaise écriture des paramètres de somme !" && exit 4
  fi
  local lig col nbcol max
  nbcol=$(expr $(echo -e "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  max=$(cellule "$1" $4 $5)
  while test $lig -ne $4 || test $col -ne $5; do
    if test $(echo "$(cellule "$1" $lig $col) > $max" | bc) -eq 1; then
      max=$(cellule "$1" $lig $col)
    fi
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  echo $max
}
