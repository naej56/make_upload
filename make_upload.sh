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
#   - vcs (script)  : http://p.outlyer.net/vcs/            #
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
txt_reset_err='\e[0m\e[31'

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
  local file="${1}"
  local file_type=$(file -b -i "${file}" | cut -d / -f1)
  if [[ ${file_type} != 'video' ]]; then
    disp_err "Omission du fichier ${txt_bold}${file}${txt_reset_err} car il est de type : ${file_type}"
    return 0
  fi
  return 1
}

# création de l'archive zip et suppression du dossier
create_zip () {
  local zip_file="${1}.zip"
  local dir_files="${1}"
  local delete_dir="n"
  zip -r "${zip_file}" "${dir_files}"

  disp_warn "Voulez-vous supprimer le dossier ${txt_bold}${dir_files}${txt_reset_warn} ? (o/N)"
  read delete_dir
  if [[ "${delete_dir,,}" == "o" || "${delete_dir,,}" == "y" ]]; then
    rm -r "${dir_files}"
  fi
}

############################################################
#                 Fonction principale                      #
############################################################

main () {
  analyse_param "$@"
  init_var

  # Traitement pour un fichier
  if [[ ${path_type} == 'f' ]]; then
    # traitement pour un fichier
    is_video "${release_name}"
    ret=$?
    if [[ $ret == 0 ]]; then
      
      exit
    else


  elif [[ ${path_type} == 'd' ]]; then
    # traitement pour un dossier
  else
    disp_err "Erreur dans l'identification du chemin donné."
    exit
  fi

}






# test si le chemin donné est un fichier
elif [[ -f "${DIR_RELEASE}" ]]; then

  release_path=$(dirname "${DIR_RELEASE}")
  release=$(basename "${DIR_RELEASE}")
  dir_prez="prez_${release}"
  file_nfo="${DIR_LAUNCH}/${dir_prez}/${release}.nfo"
  file_bbcode="${DIR_LAUNCH}/${dir_prez}/BBcode.txt"
  file_torrent="${DIR_LAUNCH}/${dir_prez}/${release}.torrent"
  cd "$release_path"

  # test si le fichier est une vidéo
  file_type=$(file -b -i "${release}" | cut -d / -f1)
  if [[ ${file_type} != 'video' ]]; then
    echo "Omission du fichier ${release} car il est de type : ${file_type}"
    exit
  fi
  
  # creation des dossiers et fichiers
  disp "Creation du dossier : ${dir_prez}"
  mkdir -p "${DIR_LAUNCH}/${dir_prez}"

  # creation du nfo
  disp "Traitement mediainfo du fichier : ${release}"
  mediainfo "${release}" > "${file_nfo}"
  disp "Fin de traitement mediainfo"

  # creation de vignettes
  disp "Creation de vignettes"
  let duration="$(mediainfo --Inform="General;%Duration%" "${release}") / 60000"
  format_duration=$(mediainfo --Inform="Video;%Duration/String3%" "${release}")
  disp "Duree de la video : ${format_duration}"
  if [[ "${duration}" -lt "20" ]]; then
    thumbnail=4
  else
    thumbnail=8
  fi
  disp "Nombre de vignettes : ${thumbnail}"
  vcs -O bg_heading='#000000' -O bg_sign='#000000' -O bg_title='#000000' -O bg_contact='#000000' -O fg_heading='#808080' -O fg_sign='#808080' -O fg_title='#FF00FF' -n ${thumbnail} -c 2 -T "${release}" -o "${DIR_LAUNCH}/${dir_prez}/${release}.jpg" "${release}"

  # upload de la vignette sur casimages.com
  disp "Upload et generation du BB code des vignettes"
  thumbnail_link=`echo n | pixup -s c "${DIR_LAUNCH}/${dir_prez}/${release}.jpg" | grep URL | sed -rn "s/.*\[img\](.*)\[\/img\].*/\1/p"`
  echo "[hide="${release}"][url=${thumbnail_link}][img=${thumbnail_link}][/url][/hide]" >> "${file_bbcode}"
  
  # creation du torrent
  disp "Creation du torrent"
  let release_size="$(stat -c "%s" "${release}") / 1048576"
  if [ ${release_size} -lt 1000 ]; then
          part_size=20
  else
          part_size=21
  fi
  mktorrent -p -l ${part_size} -a http://t411.download/ -o "${file_torrent}" "${release}"

  # création d'une archive zip et suppression des fichiers archivés
  cd "${DIR_LAUNCH}"
  create_zip "${dir_prez}"

# test si le chemin donner est un dossier
elif [ -d "${DIR_RELEASE}" ]; then
  
  release=$(basename "${DIR_RELEASE}")
  dir_prez="prez_${release}"
  cd "${DIR_RELEASE}"
  release_path=$(pwd)
  #release_files=($(ls))
  file_nfo="${DIR_LAUNCH}/${dir_prez}/${release}.nfo"
  file_bbcode="${DIR_LAUNCH}/${dir_prez}/BBcode.txt"
  file_torrent="${DIR_LAUNCH}/${dir_prez}/${release}.torrent"

  # creation des dossiers et fichiers de sortie
  disp "Creation des dossiers"
  mkdir -p "${DIR_LAUNCH}/${dir_prez}/vignettes"
  echo -e "\n" > "${DIR_LAUNCH}/${dir_prez}/BBcode.txt"

  # creation du nfo et des vignettes pour chaques fichiers
  echo "Informations pour : ${release}" > "${file_bbcode}"
  echo -e "\n" >> "${file_nfo}"

  # boucle pour chaque fichiers
  for release_file in ./*;do
   
    release_file=$(echo "${release_file}" | sed 's#\./##g')
    is_video "${release_file}"

    # allimentation du nfo 
    disp "Traitement mediainfo du fichier : ${release_file}"
    mediainfo "${release_file}" >> "${file_nfo}"
    echo -e "\n" >> "${file_nfo}"
    echo "-----------------------------------------------------------" >> "${file_nfo}"
    echo -e "\n" >> "${file_nfo}"

    # creation des vignettes
    disp "Creation des vignettes du fichier : ${release_file}"
    let duration="$(mediainfo --Inform="General;%Duration%" "${release_file}") / 60000"
    duration_format=$(mediainfo --Inform="Video;%Duration/String3%" "${release_file}")
    disp "Duree de la video : ${duration_format}"
    if [[ "${duration}" -lt "20" ]]; then
      thumbnail_number=4
    else
      thumbnail_number=8
    fi
    disp "Nombre de vignettes principales : ${thumbnail_number}"
    vcs -O bg_heading='#000000' -O bg_sign='#000000' -O bg_title='#000000' -O bg_contact='#000000' -O fg_heading='#808080' -O fg_sign='#808080' -O fg_title='#FF00FF' -n $nombreVignette -c 2 -T "${release_file}" -o "${DIR_LAUNCH}/${dir_prez}/vignettes/${release_file}.jpg" "${release_file}"

    # upload des vignettes sur casimages.com
    disp "Upload et generation du BB code de la vignette"
    thumbnail_link=$(echo n | pixup -s c "${DIR_LAUNCH}/${dir_prez}/vignettes/${release_file}.jpg" | grep URL | sed -rn "s/.*\[img\](.*)\[\/img\].*/\1/p")
    echo "[hide="${release_file}"][url=${thumbnail_link}][img=${thumbnail_link}][/url][/hide]" >> "${file_bbcode}"
  done
  
  # Creation du fichier torrent
  disp "Creation du torrent"
  cd ..
  let release_size="$(du "${release}" | cut -f1) / 1048576"
  if [ ${release_size} -lt 1000 ]; then
          part_size=20
  else
          part_size=21
  fi
  mktorrent -p -l ${part_size} -a http://t411.download/ -o "${file_torrent}" "${release}"

  # création d'une archive zip et suppression des fichiers archivés
  cd "${DIR_LAUNCH}"
  create_zip "${dir_prez}"

fi

# fin de traitement
disp "Fin de traitement"

