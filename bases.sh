#!/bin/bash

# Fonction affichant la valeur de la cellule dans la feuille
# Paramètres : Feuille, Ligne, Colonne
function cellule() {
  local row="$(echo "$1" | head -n $2 | tail -n 1)"
  echo "$row" | cut -f $3
}

# Fonction affichant l'addition de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function additionne() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$" || echo "$2" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe additionne() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  echo "$1 + $2" | bc -l
}

# Fonction affichant la soustraction de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function soustrait() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$" || echo "$2" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe soustrait() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  echo "$1 - $2" | bc -l
}

# Fonction affichant la multiplication de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function multiplie() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$" || echo "$2" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe multiplie() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  echo "$1 * $2" | bc -l
}

# Fonction affichant la division de deux valeurs
# Paramètres : Nombre 1, Nombre 2
function divise() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$" || echo "$2" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe divise() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  if test $(echo $2 | cut -d '.' -f 1) -eq 0 && test $(echo $2 | cut -d '.' -f 2) -eq 0; then
    echo "Erreur divise() ! Division par zéro" >&2 && exit 1
  fi
  echo "$1 / $2" | bc -l
}

# Fonction affichant le resultat de val1 puissance val2
# Paramètres : Nombre 1, Nombre 2
function puissance() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$" || echo "$2" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe puissance() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  echo "$1 ^ $2" | bc -l
}

# Fonction affichant le logarihme népérien de val1
# Paramètres : Nombre 1
function logarithme() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe logarithme() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  if test $(echo $1 | cut -d '.' -f 1) -le 0; then
    echo "Erreur logarithme() ! Logarithme d'un nombre négatif" >&2 && exit 1
  fi
  echo "l($1)" | bc -l
}

# Fonction affichant l'exponentiation de e à la puissance val1
# Paramètres : Nombre 1
function exponentielle() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe exponentielle() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  echo "e($1)" | bc -l
}

# Fonction affichant la racine de val1
# Paramètres : Nombre 1
function racine() {
  if echo "$1" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo "Erreur syntaxe racine() ! Chaine de caractère au lieu de nombre" >&2 && exit 1
  fi
  if test $(echo $1 | cut -d '.' -f 1) -lt 0; then
    echo "Erreur racine() ! Racine d'un nombre négatif" >&2 && exit 1
  fi
  echo "sqrt($1)" | bc -l
}

# Fonction permettant de calculer la somme à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function somme() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "Erreur somme() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
  local lig col nbcol som=0
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    som=$(additionne $som "$(cellule "$1" $lig $col)")
    if test $? -ne 0; then
      echo "Venant de Ligne : $lig, Colonne : $col" && exit 1
    fi
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  som=$(additionne $som "$(cellule "$1" $lig $col)")
  if test $? -ne 0; then
    echo "Venant de Ligne : $lig, Colonne : $col" && exit 1
  fi
  echo $som
}

# Fonction permettant de faire la moyenne à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function moyenne() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "Erreur moyenne() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
  local nbcol nbcel som
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  som=$(somme "$1" $2 $3 $4 $5)
  if test $? -ne 0; then exit 1; fi
  nbcel=$(echo "(1 + $nbcol - $3) + (($4 - $2) * $nbcol) - ($nbcol - $5)" | bc -l)
  echo "$som / $nbcel" | bc -l
}

# Fonction permettant de calculer la moyenne à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function variance() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "Erreur variance() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
  local lig col nbcol nbcel moy som=0
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  moy=$(moyenne "$1" $2 $3 $4 $5)
  if test $? -ne 0; then exit 1; fi
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
  if test $? -ne 0; then exit 1; fi
}

# Fonction permettant de calculer la médiane à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function mediane() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "Erreur mediane() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
  local lig col nbcol nbcel data=""
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    if echo "$(cellule "$1" $lig $col)" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
      echo -e "Erreur syntaxe mediane() ! Chaine de caractère au lieu de nombre\nVenant de Ligne : $lig, Colonne : $col" >&2 && exit 1
    fi
    data="$data"$(cellule "$1" $lig $col)"\n"
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  if echo "$(cellule "$1" $lig $col)" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo -e "Erreur syntaxe mediane() ! Chaine de caractère au lieu de nombre\nVenant de Ligne : $lig, Colonne : $col" >&2 && exit 1
  fi
  data="$data$(cellule "$1" $lig $col)"
  nbcel=$(echo "(1 + $nbcol - $3) + (($4 - $2) * $nbcol) - ($nbcol - $5)" | bc -l)
  echo -e "$data" | sort -n | head -n $(((nbcel + 1) / 2)) | tail -n 1
}

# Fonction permettant d'avoir le minimum à partir d'une cellule à une autre
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function minimum() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "Erreur minimum() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
  local lig col nbcol min
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  if echo "$(cellule "$1" $4 $5)" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo -e "Erreur syntaxe minimum() ! Chaine de caractère au lieu de nombre\nVenant de Ligne : $4, Colonne : $5" >&2 && exit 1
  fi
  min=$(cellule "$1" $4 $5)
  while test $lig -ne $4 || test $col -ne $5; do
    if echo "$(cellule "$1" $lig $col)" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
      echo -e "Erreur syntaxe minimum() ! Chaine de caractère au lieu de nombre\nVenant de Ligne : $lig, Colonne : $col" >&2 && exit 1
    fi
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
    echo "Erreur maximum() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
  local lig col nbcol max
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  if echo "$(cellule "$1" $4 $5)" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
    echo -e "Erreur syntaxe maximum() ! Chaine de caractère au lieu de nombre\nVenant de Ligne : $4, Colonne : $5" >&2 && exit 1
  fi
  max=$(cellule "$1" $4 $5)
  while test $lig -ne $4 || test $col -ne $5; do
    if echo "$(cellule "$1" $lig $col)" | grep -Evq "^[0-9]+(.[0-9]+)?$"; then
      echo -e "Erreur syntaxe maximum() ! Chaine de caractère au lieu de nombre\nVenant de Ligne : $lig, Colonne : $col" >&2 && exit 1
    fi
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

# Fonction permettant de concatener 2 chaines de caractères
# Paramètres : Chaine 1, Chaine 2
function concat() {
  echo "$1$2"
}

# Fonction permettant d'avoir la longueur d'une chaine de caractères
# Paramètres : Chaine 1
function length() {
  expr length "$1"
}

# Fonction permettant d'avoir la longueur d'une chaine de caractères
# Paramètres : Chaine 1, Chaine 2, Chaine 3
function substitute() {
  local s1 s2 ch="$1"
  if test "$2" = "\\" || test "$2" = "/"; then
    s1="\\$2"
  else
    s1="$2"
  fi
  if test "$3" = "\\" || test "$3" = "/"; then
    s2="\\$3"
  else
    s2="$3"
  fi
  # Le remplacement
  echo "$ch" | sed "s/$s1/$s2/"
  if test $? -ne 0; then
    echo "Erreur Sed à cause de \"$s1\" et \"$s2\" " >&2 && exit 1
  fi
}

# Fonction permettant d'avoir la taille d'un fichier
# Paramère : Le nom du fichier
function size() {
  local ch="$1"
  # On effectue les remplacement pour le traitement des éventuel "\n" et "\t"
  if test "$optScin" != "\t"; then
    ch="$(echo "$ch" | sed "s/$optScin/\\\t/g")"
  fi
  if test "$optSlin" != "\n"; then
    ch="$(echo "$ch" | sed "s/$optSlin/\\\n/g")"
  fi
  if ! test -f "$ch"; then
    echo "Le fichier $ch n'existe pas" >&2 && exit 1
  fi
  wc -c "$ch" | cut -d ' ' -f1
}

# Fonction permettant d'avoir le nombre de ligne d'un fichier
# Paramère : Le nom du fichier
function lines() {
  local ch="$1"
  # On effectue les remplacement pour le traitement des éventuel "\n" et "\t"
  if test "$optScin" != "\t"; then
    ch="$(echo "$ch" | sed "s/$optScin/\\\t/g")"
  fi
  if test "$optSlin" != "\n"; then
    ch="$(echo "$ch" | sed "s/$optSlin/\\\n/g")"
  fi
  if ! test -f "$ch"; then
    echo "Le fichier $ch n'existe pas" >&2 && exit 1
  fi
  wc -l "$ch" | cut -d ' ' -f1
}

# Fonction permettant d'executer une commande bash
# Paramère : La commande
function shell() {
  local ch="$1"
  # On effectue les remplacement pour le traitement des éventuel "\n" et "\t"
  if test "$optScin" != "\t"; then
    ch="$(echo "$ch" | sed "s/$optScin/\\\t/g")"
  fi
  if test "$optSlin" != "\n"; then
    ch="$(echo "$ch" | sed "s/$optSlin/\\\n/g")"
  fi

  ch="$($1)"
  if test $? -ne 0; then
    echo "Erreur lors de l'execution de la commande \"$ch\"" >&2 && exit 1
  fi
  # Si il ya des '\t' et '\n'
  if test "$optScin" != "\t"; then
    ch="$(echo -e "$ch" | tr "\t" "$optScin")"
  fi
  if test "$optSlin" != "\n"; then
    ch="$(echo -en "$ch" | tr "\n" "$optSlin")"
  fi

  echo "$ch"
}

# Fonction permettant de gerer les problème avec la fonction display
# Paramètre : Ligne 1, Colonne 1, Ligne 2, Colonne 2
function display() {
  if (test $2 -gt $4) || (test $2 -eq $4 && test $3 -gt $5); then
    echo "Erreur display() ! La première cellule doit venir avant la deuxième !" >&2 && exit 1
  fi
}
