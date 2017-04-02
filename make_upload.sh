#!/bin/bash

############################################################
#                                                          #
#  Auteur  :  NaeJ                                         #
#  Version :  1.0.0.3                                      #
#  Script  :  make_upload.sh                               #
#                                                          #
############################################################
#                                                          #
#  Environement : debian 7.1 wheezy                        #
#  Dependances  :                                          #
#   - mktorrent     : http://mktorrent.sourceforge.net/    #
#   - mediaInfo     : https://mediaarea.net/fr/MediaInfo   #
#   - pixup         : https://framagit.org/PixUP/pixup     #
#   - vcs           : http://p.outlyer.net/vcs/            #
#                                                          #
############################################################
#                                                          #
#  Github : https://github.com/naej56/make_upload          #
#                                                          #
############################################################
#                                                          #
#  Usage  :                                                #
#  ./make_upload.sh [fichier ou dossier]                   #
#                                                          #
############################################################


clear
############################################################
#                      Variables                           #
############################################################
DIR_LAUNCH=$(pwd)
RELEASE='./'

usage="Usage : ./make_upload.sh [FICHIER]"

# mise en forme de texte
txt_bold='\e[1m'
txt_green='\e[32m'
txt_yellow='\e[33m'
txt_red='\e[31m'
txt_reset='\e[0m'
txt_reset_succ='\e[0m\e[32m'
txt_reset_warn='\e[0m\e[33m'
txt_reset_err='\e[0m\e[31m'

############################################################
#                      Fonctions                           #
############################################################

# Affiche sur la sortie standard avec un horodatage
disp () {
  local timestamp=$(date +[%H:%M:%S])
  echo -e "${timestamp} : ${1} ${txt_reset}"
}

disp_succ () {
  local timestamp=$(date +[%H:%M:%S])
  echo -e "${timestamp} :${txt_green} ${1} ${txt_reset}"
}

disp_warn () {
  local timestamp=$(date +[%H:%M:%S])
  echo -e "${timestamp} :${txt_yellow} ${1} ${txt_reset}"
}

disp_err () {
  local timestamp=$(date +[%H:%M:%S])
  echo -e "${timestamp} :${txt_red} ${1} ${txt_reset}"
}

# Test les paramétres passés au script
analyse_param () {
  if [[ ${#} -eq 0 ]]; then
    disp "${usage}"
    exit
  fi

  if [[ ! -e "${1}" ]]; then
    disp_err "${txt_bold}${1}${txt_reset} n'est pas un chemin valide ou le fichier n'existe pas."
    exit
  elif [[ -f "${1}" ]]; then
    path_type='f'
    RELEASE="${1}"
  elif [[ -d "${1}" ]]; then
    path_type='d'
    RELEASE="${1}"
  fi
}

# initialisation de variables
init_var () {
  release_path=$(dirname "${RELEASE}")
  release_name=$(basename "${RELEASE}")
  dir_prez="prez_${release_name}"
  file_nfo="${DIR_LAUNCH}/${dir_prez}/${release_name}.nfo"
  file_bbcode="${DIR_LAUNCH}/${dir_prez}/BBcode.txt"
  file_torrent="${DIR_LAUNCH}/${dir_prez}/${release_name}.torrent"
}

# test si le fichier est une vidéo
is_video () {
  local input_file="${1}"
  local file_type=$(file -b -i "${input_file}" | cut -d / -f1)
  if [[ ${file_type} != 'video' ]]; then
    disp_err "Omission du fichier ${txt_bold}${input_file}${txt_reset_err} car il est de type : ${txt_bold}${file_type}${txt_reset_err}"
    return 0
  fi
  return 1
}

# création du nfo avec info issue de mediainfo
create_nfo () {
  local input_file="${1}"
  local output_file="${file_nfo}"
  disp "Creation du fichier nfo ..."
  mediainfo "${input_file}" >> "${output_file}"
  echo "----------------------------------------------" >> "${output_file}"
}

# création et upload des vignettes
create_thumbnail () {
  local input_file="${1}"
  local output_file="${2}"
  local input_file_name=$(basename "${input_file}")
  local thumbnail_file="${DIR_LAUNCH}/${dir_prez}/${input_file_name}.jpg"
  disp "Creation de vignettes ..."
  let local duration="$(mediainfo --Inform="General;%Duration%" "${input_file}") / 60000"
  local format_duration=$(mediainfo --Inform="Video;%Duration/String3%" "${input_file}")
  if [[ "${duration}" -lt "20" ]]; then
    thumbnail=4
  else
    thumbnail=8
  fi
  disp "Durée de la vidéo : ${format_duration}, nombre de vignettes : ${thumbnail}"
  vcs -O bg_heading='#000000' -O bg_sign='#000000' -O bg_title='#000000' -O bg_contact='#000000' -O fg_heading='#808080' -O fg_sign='#808080' -O fg_title='#FF00FF' -n ${thumbnail} -c 2 -T "${input_file}" -o "${thumbnail_file}" "${input_file}"
  disp "Upload et generation du BB code des vignettes"
  thumbnail_links=$(echo n | pixup -s c "${thumbnail_file}" | sed -rn "s/.*\[img\](.*)\[\/img\].*/\1/p")
  thumbnail_link_mini=$(echo "${thumbnail_links}" | cut -d$'\n' -f1)
  thumbnail_link=$(echo "${thumbnail_links}" | cut -d$'\n' -f2)
  echo "[url=${thumbnail_link}][img width=\"200\"]${thumbnail_link_mini}[/img][/url]" >> "${output_file}"
}

# création du fichier torrent
create_torrent () {
  local input_file="${1}"
  local output_file="${2}"
  disp "Creation du torrent ..."
  let local release_size="$(stat -c "%s" "${input_file}") / 1048576"
  if [ ${release_size} -lt 1000 ]; then
          part_size=20
  else
          part_size=21
  fi
  mktorrent -p -l ${part_size} -a http://t411.download/ -o "${output_file}" "${input_file}"
}

# création de l'archive zip et suppression du dossier
create_zip () {
  local input_file="${1}"
  local output_file="${1}.zip"
  local delete_dir='n'
  cd "${DIR_LAUNCH}"
  zip -r "${output_file}" "${input_file}"

  disp_warn "Voulez-vous supprimer le dossier ${txt_bold}${input_file}${txt_reset_warn} ? (o/${txt_bold}N${txt_reset_warn})"
  read delete_dir
  if [[ "${delete_dir,,}" == "o" || "${delete_dir,,}" == "y" ]]; then
    rm -r "${input_file}"
  fi
}

############################################################
#                 Fonction principale                      #
############################################################

main () {
  analyse_param "$@"
  init_var

  cd "${release_path}"
  disp "Creation du dossier : ${dir_prez}"
  mkdir "${DIR_LAUNCH}/${dir_prez}"
  touch "${file_nfo}" "${file_bbcode}"
  if [[ ${path_type} == 'f' ]]; then
    is_video "${release_name}"
    ret=$?
    if [[ $ret == 0 ]]; then
      rm -r "${DIR_LAUNCH}/${dir_prez}"
      disp "Aucun autre fichier a traiter fin de traitement."
      exit
    fi
    create_nfo "${release_name}" "${file_nfo}"
    create_thumbnail "${release_name}" "${file_bbcode}"
  elif [[ ${path_type} == 'd' ]]; then
    cd "${release_name}"
    find . -type f | while IFS=$'\n' read release_file ; do
      release_file=$(echo "${release_file}" | sed 's#\./##g')
      is_video "${release_file}"
      ret=$?
      if [[ $ret == 0 ]]; then
        continue
      fi
      create_nfo "${release_file}" "${file_nfo}"
      create_thumbnail "${release_file}" "${file_bbcode}"
    done
  else
    disp_err "Outch ..."
  fi
  if [[ ${path_type} == 'd' ]]; then cd ../; fi
  create_torrent "${release_name}" "${file_torrent}"
  create_zip "${dir_prez}"

  disp_succ "Fin de traitement !!!!"
}



main "$@"
