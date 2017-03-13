#!/bin/bash

############################################################
#                                                          #
#  Auteur  :  NaeJ                                         #
#  Version :  1.0.0.2                                      #
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
# Variables
DIR_LAUNCH=$(pwd)
DIR_RELEASE="${1}"

# fonctions
disp () {
  timestamp=$(date +[%H:%M:%S])
  echo "${timestamp} : ${1}"
}

is_video () {
  # test si le fichier est une video
  local file="${1}"
  local file_type=$(file -b -i "${file}" | cut -d / -f1)
  if [[ ${file_type} != 'video' ]]; then
    echo "Omission du fichier ${file} car il est de type : ${file_type}"
    continue
  fi
}

# verif param fournis au script
if [[ -z "${DIR_RELEASE}" ]]; then
  echo "Usage : ./make_upload.sh [fichier ou dossier]"
  exit
fi

# test pour savoir si le chemin est valide
if [[ ! -e "${DIR_RELEASE}" ]]; then
  echo "${DIR_RELEASE} n'existe pas, merci de renseigner un chemin valide."
  exit
  
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

  # TODO    : creation d'une archive zip contenant le fichier torrent, le BBcode et le nfo et proposer de supprimer les fichiers pour ne concerver que le zip
  cd "${DIR_LAUNCH}"

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

    # creation de la vignettes
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

  # TODO    : creation d'une archive zip contenant le fichier torrent, le BBcode et le nfo et proposer de supprimer les fichiers pour ne concerver que le zip
fi

# fin de traitement
disp "Fin de traitement"

