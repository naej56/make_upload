# make_upload
Script bash qui permet de simplifier la création de torrent et de prez pour des fichiers vidéo.
Permet la création automatique d'un dossier prez_nom_du_fichier_a_partager dans le répertoire où la commande est lancée.
Va créer dans ce dossier :
- Un fichier nom_du_fichier_a_partager.nfo qui contient le résultat du mediainfo
- Un dossier qui contient les vignettes des vidéos si il y en a plusieurs ou directement la vignette dans le cas d'une vidéo unique
- Un fichier BBcode.txt qui contient le BBcode pour afficher la (les) vignette(s) générée(s)
- Le fichier nom_du_fichier_a_partager.torrent

**Utilisation :**

Rendre le script **executable** avec la commande suivante :

``chmod +x make_upload.sh``

Lancer la commande :

``./make_upload.sh /chemin/vers/le/dosier/a/partager``

Dans ce cas le dossier prez_nom_du_fichier_a_partager sera toujours générer dans le dossier où se trouve le script.

# Todo
- [x] ~~Support des chemins avec espaces~~
- [ ] Ajout d'un fichier de conf
- [x] ~~Ajout de la création d'une archvie avec option pour supprimer les fichiers~~
- [ ] Gérer la récursivité dans un dossier
- [x] ~~Ajouter un test pour ne traiter que les fichiers vidéo~~
- [ ] Test le bon fonctionnement en utilisant le script avec un ``alias`` et depuis le ``$PATH``
- [ ] Refactoriser le code pour utiliser des fonctions pour la création des vignettes, la génération du fichier torrent, du fichier BBcode.txt et du fichier nfo ainsi que pour la création du dossier contenant de sortie
- [ ] Ajouter un fichier texte avec les liens "brut" vers les vignettes et leurs miniatures
- [ ] Modifier la génération du BB code pour pouvoir le personaliser avec le fichier de conf
- [ ] Ajouter une prise en charge d'options (ex. : -c conf_file -a tracker_annonce_url -o output_dir -p (torrent privé))
- [ ] Ajouter une mise ne forme des textes
- [ ] Masquer la sortie standard des différents scripts / commandes (les rediriger vers un fichier log ?)

# Change logs
### 1.0.0.3
- Ajout de la création d'une archvie avec option pour supprimer les fichiers
- Ajout de commentaires

### 1.0.0.2
- Ajout du support des espaces dans les nom de dossiers et de fichiers
- Ajout du test pour ne traiter que les fichiers vidéo
- Ajout de l'affichage Usage si le script est mal lancer

#### 1.0.0.1
Nettoyage du code pour le rendre plus lisible

#### 1.0.0.0
Première release
