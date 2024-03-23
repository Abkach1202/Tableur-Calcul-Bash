#!/bin/bash

###################################################
#          Abdoulaye KATCHALA MELE                #
#           L3 Informatique TD2-C                 #
###################################################

# Traitement des fonctions de bases du projet
source bases.sh
# Traitement des fonctions utilitaires du projet
source utilitaires.sh

##### Programme principale #####

export optScin="\t"
export optSlin="\n"
optScout="\t"
optSlout="\n"

# Gestion des options
while test $# -ne 0; do
  case "$1" in
  "-in")
    if test "$(expr substr "$2" 1 1)" = '-'; then
      echo "l'option -in doit avoir un argument !" >&2 && exit 1
    fi
    optIn="$2"
    shift 2
    ;;
  "-out")
    if test "$(expr substr "$2" 1 1)" = '-'; then
      echo "l'option -out doit avoir un argument !" >&2 && exit 1
    fi
    optOut="$2"
    shift 2
    ;;
  "-scin")
    if test $(expr length "$2") -ne 1 && test "$2" != "\n" && test "$2" != "\t"; then
      echo "l'option -scin doit contenir exactement un séparateur !" >&2 && exit 1
    fi
    export optScin="$2"
    shift 2
    ;;
  "-scout")
    if test $(expr length "$2") -ne 1 && test "$2" != "\n" && test "$2" != "\t"; then
      echo "l'option -scout doit contenir exactement un séparateur !" >&2 && exit 1
    fi
    optScout="$2"
    shift 2
    ;;
  "-slin")
    if test $(expr length "$2") -ne 1 && test "$2" != "\n" && test "$2" != "\t"; then
      echo "l'option -slin doit contenir exactement un séparateur !" >&2 && exit 1
    fi
    export optSlin="$2"
    shift 2
    ;;
  "-slout")
    if test $(expr length "$2") -ne 1 && test "$2" != "\n" && test "$2" != "\t"; then
      echo "l'option -slout doit contenir exactement un séparateur !" >&2 && exit 1
    fi
    optSlout="$2"
    shift 2
    ;;
  "-inverse")
    optInverse=1
    shift 1
    ;;
  "-help")
    echo -e "La syntaxe est :\ntableur [-in feuille] [-out résultat] [-scin sep] [-scout sep] [-slin sep] [-slout sep] [-inverse]" && exit 0
    ;;
  *)
    feuille="$1"
    shift 1
    ;;
  esac
done

# Traitement des options
if test "$optIn" != ""; then
  if test -f "$optIn"; then
    feuille="$(cat "$optIn")"
  else
    echo "Le fichier $optIn n'existe pas !" >&2 && exit 1
  fi
fi

# Remplacement des separateurs d'entrée par le retour à la ligne et tabulation
feuille="$(echo -e "$feuille")"
if test "$optScin" != "\t"; then
  feuille="$(echo "$feuille" | tr "$optScin\t" "\t$optScin")"
fi
if test "$optSlin" != "\n"; then
  feuille="$(echo -n "$feuille" | tr "$optSlin\n" "\n$optSlin")"
fi

# Calcul du nombre de lignes et du nombre de colonnes
nblig=$(echo "$feuille" | wc -l)
nbcol=$(expr $(echo "$feuille" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)

# Les variables pour les cellules à afficher
display=""

# On parcourt pour voir la fonction display
lig=1
col=1
while test $lig -le $nblig; do
  ligcol="$(cellule "$feuille" $lig $col | grep -Eo "display\(l[0-9]+c[0-9]+,l[0-9]+c[0-9]+\)")"
  if test "$ligcol" != ""; then
    display="$(echo -en "$display\t")$(echo "$ligcol" | grep -Eo "l[0-9]+c[0-9]+,l[0-9]+c[0-9]+")"
  fi
  if test $col -eq $nbcol; then
    lig=$((lig + 1))
    col=1
  else
    col=$((col + 1))
  fi
done

# Le traitement de la feuille de la première cellule à la dernière cellule
feuille="$(traite_intervalle_cellule "$feuille" 1 1 $nblig $nbcol)"
if test $? -ne 0; then exit 1; fi

# Inversion des cellules si l'option -inverse est acyivée
if test "$optInverse" != ""; then
  tmp="$feuille"
  for i in $(seq $nblig); do
    for j in $(seq $((nbcol - i))); do
      if valide_ligcol "$feuille" $i $((j + i)) && valide_ligcol "$feuille" $((j + i)) $i; then
        feuille="$(remplace_cellule "$feuille" $i $((j + i)) "$(cellule "$feuille" $((j + i)) $i)")"
      fi
    done
  done
  for i in $(seq $nblig); do
    for j in $(seq $((nbcol - i))); do
      if valide_ligcol "$feuille" $i $((j + i)) && valide_ligcol "$feuille" $((j + i)) $i; then
        feuille="$(remplace_cellule "$feuille" $((j + i)) $i "$(cellule "$tmp" $i $((j + i)))")"
      fi
    done
  done
fi

# On garde seulement les cellules à afficher
if test "$display" != ""; then
  lig=1
  col=1
  while test $lig -le $nblig; do
    bool=0
    for var in $display; do
      ligcol1="$(ligne_colonne $(echo "$var" | cut -d ',' -f1))"
      ligcol2="$(ligne_colonne $(echo "$var" | cut -d ',' -f2))"
      if appartient $lig $col $ligcol1 $ligcol2; then
        bool=1
      fi
    done
    if test $bool -eq 0; then feuille="$(remplace_cellule "$feuille" $lig $col " ")"; fi
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
fi

# Remplacement des retour à la ligne et des tabulation par les separateurs de sortie
if test "$optScin" != "\t"; then
  feuille="$(echo "$feuille" | sed "s/$optScin/\\\t/g")"
fi
feuille="$(echo "$feuille" | sed "s/\t/$optScout/g")"

if test "$optSlin" != "\n"; then
  feuille="$(echo "$feuille" | sed "s/$optSlin/\\\n/g")"
fi
feuille="$(echo -n "$feuille" | tr "\n" "$optSlout")"

# Affichage du resultat sur la sortie specifié
if test "$optOut" != ""; then
  echo "$feuille" >"$optOut"
else
  echo "$feuille"
fi
