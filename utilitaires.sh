#!/bin/bash

# Variable globale pour eviter la recursion des cellules
export traitement=""

# Fonction permettant d'avoir la ligne et la colonne d'une notation licj de cellule
# Paramètre : Chaine contenant la notation licj
function ligne_colonne() {
  echo "$1" | sed 's/l//' | sed 's/c/ /'
}

# Fonction permettant de voir si la ligne et la colonne d'une cellule est valide
# Paramètre : Feuille, Ligne, Colonne
function valide_ligcol() {
  local nblig nbcol
  nblig=$(echo "$1" | wc -l)
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  test $2 -le $nblig && test $3 -le $nbcol
}

# Fonction permettant de voir si la ligne et la colonne appartient à une intervalle
# Paramètre : Ligne, Colonne, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function appartient() {
  if test $1 -lt $3; then return 1; fi
  if test $1 -eq $3 && test $2 -lt $4; then return 1; fi
  if test $1 -gt $5; then return 1; fi
  if test $1 -eq $5 && test $2 -gt $6; then return 1; fi
  return 0
}

# Fonction permettant de remplacer le contenu d'une cellule par un autre
# Paramètres : Feuille, Ligne, Colonne, Le nouveau contenu
function remplace_cellule() {
  local row new_row
  row="$(echo "$1" | head -n $2 | tail -n 1)"
  new_row="$(echo "$row" | sed -E "s/(^([^\t]+\t){$(expr $3 - 1)})[^\t]+/\1$4/")"
  echo "$1" | head -n $(expr $2 - 1)
  echo "$new_row"
  echo "$1" | tail -n +$(expr $2 + 1)
}

# Fonction permettant d'avoir le nom et les 2 paramètres d'une fonction
# Utilise le nombre de parenthèses ouvertes et fermées pour distinguer les paramètres
# Paramètres : Chaine de Fonction
function nom_parametres() {
  # Si ça commence par un crochet, on traite le cas de [cel]
  if test "$(expr substr "$1" 1 1)" = '['; then
    echo -e "cellule\t$(echo "$1" | egrep -o 'l[0-9]+c[0-9]+')"
    return
  fi
  # Si non
  local chaine params ouv=0

  # On affiche le nom de la fonction
  echo -n "$(echo $1 | cut -d '(' -f 1)"

  # On s'intéresse qu'aux paramètre seulement et on les parcours caractère par caractère
  params="$(echo $1 | sed -E "s/(^[^(]+\(|\)$)//g")"
  OLDIFS="$IFS"
  export IFS="$(echo -e '\t')"
  for car in $(echo "$params" | sed 's/./&\t/g'); do
    if test "$car" = '('; then
      ouv=$((ouv + 1)) # on ajoute 1 au compteur de parenthèse
      chaine="${chaine}${car}"
    elif test "$car" = ')'; then
      ouv=$((ouv - 1)) # On diminue 1 au compteur de parenthèse
      chaine="${chaine}${car}"
    # Si on voit une virgule et que notre compteur est nul, on affiche le premier paramètre
    elif test "$car" = ',' && test $ouv -eq 0; then
      echo -en "\t" && echo -n "$chaine"
      chaine=""
    else
      chaine="${chaine}${car}"
    fi
  done
  export IFS="$OLDIFS"
  if test $ouv -ne 0; then
    echo "Erreur ! Problème de parenthésage" >&2 && exit 1
  fi
  echo -en "\t" && echo "$chaine" # On affiche le deuxième paramètre
}

# Fonction permettant de traiter une cellule de la feuille recursivement
# Elle retourne une nouvelle feuille avec la cellule mise à jour
# Paramètres : Feuille, Ligne, Colonne
function traite_cellule() {
  # Erreur de cellule invalide
  if ! valide_ligcol "$1" $2 $3; then
    echo -e "Erreur ! Numéro de ligne et colonne invalide ($2, $3)\nVenant de Ligne : $2, Colonne : $3" >&2 && exit 1
  fi

  # Si la cellule est déjà en cours de traitement ou pas, Il y'a recursion
  if echo "$traitement" | grep -q "l${2}c${3}"; then
    echo "Boucle infinie ! Recursion sur la cellule l${2}c${3}" >&2 && exit 1
  fi

  # On récupère la cellule
  local calcul="$(cellule "$1" $2 $3)"

  # Si le contenu commence pas par un '=', il renvoie la feuille
  if test "$(expr substr "$calcul" 1 1)" != '='; then
    echo "$1"
    return
  fi
  # Si non, cela veut dire que c'est un calcul
  local nouv_feuille nblig res
  # on enlève l'égal du calcul
  calcul="$(echo "$calcul" | sed 's/=//')"
  nblig=$(echo -e "$1" | wc -l)

  # On ajoute la cellule dans notre liste de traitement
  export traitement="${traitement}l${2}c${3} "

  # On execute le calcul de la fonction tout en recuperant le resultat et la feuille
  res="$(execute_fonction "$1" "$calcul")"
  if test $? -ne 0; then
    echo "Venant de Ligne : $2, Colonne : $3" >&2 && exit 1
  fi
  nouv_feuille="$(echo "$res" | head -n $nblig)"
  res="$(echo -e "$res" | tail -n +$((nblig + 1)))"

  # On enleve la cellule dans notre liste de traitement
  export traitement="$(echo "$traitement" | sed "s/l${2}c${3} //g")"

  # On remplace le resultat dans la nouvelle feuille
  remplace_cellule "$nouv_feuille" $2 $3 "$res"
}

# Fonction permettant de faire le traitement de tous les cellules entre ceux passées en paramètre
# Elle retourne la feuille avec toutes les cellules mises à jour
# Paramètres : Feuille, Ligne 1, Colonne 1, Ligne 2, Colonne 2
function traite_intervalle_cellule() {
  local lig col nbcol nouv_feuille="$1"
  nbcol=$(expr $(echo "$1" | head -n 1 | egrep -o "$(echo -e "\t")" | wc -l) + 1)
  lig=$2
  col=$3
  while test $lig -ne $4 || test $col -ne $5; do
    nouv_feuille="$(traite_cellule "$nouv_feuille" $lig $col)"
    if test $? -ne 0; then exit 1; fi
    if test $col -eq $nbcol; then
      lig=$((lig + 1))
      col=1
    else
      col=$((col + 1))
    fi
  done
  nouv_feuille="$(traite_cellule "$nouv_feuille" $lig $col)"
  if test $? -ne 0; then exit 1; fi
  echo "$nouv_feuille"
}

# Fonction permettant d'executer et de faire le calcul d'une fonction
# Elle retourne la feuille mis à jour suivi du resultat du calcul
# Paramètres : Feuille, La chaine de la fonction
function execute_fonction() {
  local calcul fonc param1 param2 param3 val1 val2 val3 res nblig nouv_feuille="$1"
  # On sépare le nom de la fonction et ses paramètres
  calcul="$(nom_parametres "$2")"
  if test $? -ne 0; then
    echo "Fonction : $2" >&2 && exit 1
  fi
  fonc="$(echo "$calcul" | cut -f 1)"   # nom de la fonction
  param1="$(echo "$calcul" | cut -f 2)" # Premier paramètre
  param2="$(echo "$calcul" | cut -f 3)" # Deuxième eventuel paramètre
  param3="$(echo "$calcul" | cut -f 4)" # troisième eventuel paramètre
  nblig=$(echo "$1" | wc -l)

  # On traite le premier paramètre
  res="$(traite_parametre "$nouv_feuille" $nblig "$param1")"
  nouv_feuille="$(echo "$res" | head -n $nblig)"
  param1="$(echo "$res" | head -n $((nblig + 1)) | tail -n 1)"
  val1="$(echo "$res" | tail -n +$((nblig + 2)))"

  # On traite le deuxième paramètre
  res="$(traite_parametre "$nouv_feuille" $nblig "$param2")"
  nouv_feuille="$(echo "$res" | head -n $nblig)"
  param2="$(echo "$res" | head -n $((nblig + 1)) | tail -n 1)"
  val2="$(echo "$res" | tail -n +$((nblig + 2)))"

  # On traite le  paramètre
  res="$(traite_parametre "$nouv_feuille" $nblig "$param3")"
  nouv_feuille="$(echo "$res" | head -n $nblig)"
  param3="$(echo "$res" | head -n $((nblig + 1)) | tail -n 1)"
  val3="$(echo "$res" | tail -n +$((nblig + 2)))"

  # On applique la fonction approprié en fonction de $fonc
  case "$fonc" in
  "cellule")
    res="$val1"
    ;;
  "+")
    res=$(additionne $val1 $val2)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "-")
    res=$(soustrait $val1 $val2)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "*")
    res=$(multiplie $val1 $val2)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "/")
    res=$(divise $val1 $val2)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "^")
    res=$(puissance $val1 $val2)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "ln")
    res=$(logarithme $val1)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "e")
    res=$(exponentielle $val1)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "sqrt")
    res=$(racine $val1)
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "somme")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur somme() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(somme "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "moyenne")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur moyenne() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(moyenne "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "variance")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur variance() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(variance "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "ecartype")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur ecartype() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(ecartype "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "mediane")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur mediane() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(mediane "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "min")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur min() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(minimum "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "max")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur max() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    nouv_feuille="$(traite_intervalle_cellule "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))"
    if test $? -ne 0; then exit 1; fi
    res=$(maximum "$nouv_feuille" $(ligne_colonne "$param1") $(ligne_colonne "$param2"))
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "concat")
    res="$(concat "$val1" "$val2")"
    ;;
  "length")
    res="$(length "$val1")"
    ;;
  "substitute")
    res="$(substitute "$val1" "$val2" "$val3")"
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "size")
    res="$(size "$val1")"
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "lines")
    res="$(lines "$val1")"
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "shell")
    res="$(shell "$val1")"
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  "display")
    if test $(expr "$param1" : '^l[0-9]\+c[0-9]\+$') -eq 0 || test $(expr "$param2" : '^l[0-9]\+c[0-9]\+$') -eq 0; then
      echo -e "Erreur somme() ! Les paramètres doivent être des cellules\nFonction : $2" >&2 && exit 1
    fi
    res="$2"
    display $(ligne_colonne "$param1") $(ligne_colonne "$param2")
    if test $? -ne 0; then
      echo "Fonction : $2" >&2 && exit 1
    fi
    ;;
  *)
    echo "Erreur ! $2 ne correspond à aucune fonction !" >&2 && exit 1
    ;;
  esac

  # On retourne la nouvelle feuille et le resultat
  echo "$nouv_feuille"
  echo "$res"
}

# Fonction permettant de gerer les paramètres d'une fonction (faire des éventuels calculs)
# Elle retourne la feuille mis à jour suivi du paramètre et du resultat du calcul
# Paramètres : Feuille, le nombre de ligne de la feuille, Le contenu du paramètre
function traite_parametre() {
  local param val res nouv_feuille="$1"
  param="$3"
  # Si le paramètre est une fonction, on l'execute et on garde la valeur
  if test $(expr index "$param" "\([") -ne 0; then
    res="$(execute_fonction "$nouv_feuille" "$param")"
    if test $? -ne 0; then exit 1; fi
    nouv_feuille="$(echo "$res" | head -n $nblig)"
    param="$(echo "$res" | tail -n +$(expr $2 + 1))"
  fi
  # si il est au format licj, on traite la cellule et on garde la valeur
  if test $(expr "$param" : '^l[0-9]\+c[0-9]\+$') -ne 0; then
    nouv_feuille="$(traite_cellule "$nouv_feuille" $(ligne_colonne "$param"))"
    if test $? -ne 0; then exit 1; fi
    val="$(cellule "$nouv_feuille" $(ligne_colonne "$param"))"
  else
    val="$param"
  fi
  # On retourne la nouvelle feuille et le resultat
  echo "$nouv_feuille"
  echo "$param" | head -n 1
  echo "$val"
}
