local addonId = ...
local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "frFR")
local L = languageTable

L["S_APOWER_AVAILABLE"] = "Disponible"
L["S_APOWER_NEXTLEVEL"] = "Niveau suivant"
L["S_DECREASESIZE"] = "Réduire la taille"
L["S_ENABLED"] = "Activé"
L["S_ERROR_NOTIMELEFT"] = "Cette quête n'a pas de temps restant."
L["S_ERROR_NOTLOADEDYET"] = "Cette quête n'est pas encore chargée, merci de patienter quelques secondes."
L["S_FACTION_TOOLTIP_SELECT"] = [=[
Clic: sélectionner cette faction]=]
L["S_FACTION_TOOLTIP_TRACK"] = [=[
Shift + Clic: suivre les quêtes de cette faction]=]
L["S_FLYMAP_SHOWTRACKEDONLY"] = "Suivi seulement"
L["S_FLYMAP_SHOWTRACKEDONLY_DESC"] = "Afficher seulement les quêtes suivies"
L["S_FLYMAP_SHOWWORLDQUESTS"] = "Affiche les Expéditions"
L["S_GROUPFINDER_ACTIONS_CANCEL_APPLICATIONS"] = [=[cliquez pour se désinscrire... 
]=]
L["S_GROUPFINDER_ACTIONS_CANCELING"] = "annulation..."
L["S_GROUPFINDER_ACTIONS_CREATE"] = [=[aucun groupe trouvé? Cliquez pour en créer un
]=]
L["S_GROUPFINDER_ACTIONS_CREATE_DIRECT"] = "créer un groupe"
L["S_GROUPFINDER_ACTIONS_LEAVEASK"] = "Quitter le groupe?"
L["S_GROUPFINDER_ACTIONS_LEAVINGIN"] = [=[Sortie du groupe dans (cliquez pour quitter maintenant):
]=]
L["S_GROUPFINDER_ACTIONS_RETRYSEARCH"] = "nouvelle recherche"
L["S_GROUPFINDER_ACTIONS_SEARCH"] = "cliquez pour chercher un groupe"
L["S_GROUPFINDER_ACTIONS_SEARCH_RARENPC"] = [=[chercher un groupe pour tuer cette élite
]=]
L["S_GROUPFINDER_ACTIONS_SEARCH_TOOLTIP"] = "Rejoindre un groupe faisant cette quête"
L["S_GROUPFINDER_ACTIONS_SEARCHING"] = "recherche en cours..."
L["S_GROUPFINDER_ACTIONS_SEARCHMORE"] = "cliquez pour chercher plus de joueurs"
L["S_GROUPFINDER_ACTIONS_SEARCHOTHER"] = "Quitter et chercher un autre groupe?"
L["S_GROUPFINDER_ACTIONS_UNAPPLY1"] = [=[cliquez pour se désinscrire et créer un nouveau groupe
]=]
L["S_GROUPFINDER_ACTIONS_UNLIST"] = "cliquez pour désinscrire votre groupe"
L["S_GROUPFINDER_ACTIONS_UNLISTING"] = "désinscription..."
L["S_GROUPFINDER_ACTIONS_WAITING"] = "en attente..."
L["S_GROUPFINDER_AUTOOPEN_RARENPC_TARGETED"] = "Ouverture auto. lors du ciblage d'une élite."
L["S_GROUPFINDER_ENABLED"] = "Ouverture auto. pour chaque nouvelle quête"
L["S_GROUPFINDER_LEAVEOPTIONS"] = "Option de sortie de groupe"
L["S_GROUPFINDER_LEAVEOPTIONS_AFTERX"] = "Quitter après x secondes"
L["S_GROUPFINDER_LEAVEOPTIONS_ASKX"] = "Pas de sortie auto., mais demander après x secondes"
L["S_GROUPFINDER_LEAVEOPTIONS_DONTLEAVE"] = "Ne pas afficher le menu de sortie"
L["S_GROUPFINDER_LEAVEOPTIONS_IMMEDIATELY"] = "Quitter dès que la quête est terminée"
L["S_GROUPFINDER_NOPVP"] = "Éviter les royaumes PVP"
L["S_GROUPFINDER_OT_ENABLED"] = "Afficher les boutons sur le traqueur d'objectifs"
L["S_GROUPFINDER_QUEUEBUSY"] = "vous êtes déjà en file d'attente."
L["S_GROUPFINDER_QUEUEBUSY2"] = "impossible d'afficher la fenêtre de recherche de groupe: vous êtes déjà dans un groupe ou en file d'attente."
L["S_GROUPFINDER_RESULTS_APPLYING"] = "Il y a %d groupes restants, re-cliquez"
L["S_GROUPFINDER_RESULTS_APPLYING1"] = "Il reste 1 groupe à rejoindre, re-cliquez :"
L["S_GROUPFINDER_RESULTS_FOUND"] = [=[%d groupes trouvés
cliquez pour les rejoindre]=]
L["S_GROUPFINDER_RESULTS_FOUND1"] = [=[un groupe trouvé
cliquez pour le rejoindre]=]
L["S_GROUPFINDER_RESULTS_UNAPPLY"] = "%d inscriptions restantes..."
L["S_GROUPFINDER_RIGHTCLICKCLOSE"] = "clic droit pour fermer"
L["S_GROUPFINDER_SECONDS"] = "Secondes"
L["S_GROUPFINDER_TITLE"] = "Recherche de groupe"
L["S_GROUPFINDER_TUTORIAL1"] = "Faites vos expéditions rapidement grâce à un groupe!"
L["S_INCREASESIZE"] = "Augmenter la taille"
L["S_MAPBAR_FILTER"] = "Filtre"
L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES"] = "Objectifs de faction"
L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES_DESC"] = "Afficher les quêtes de faction, même si elles sont filtrées."
L["S_MAPBAR_OPTIONS"] = "Options"
L["S_MAPBAR_OPTIONSMENU_ARROWSPEED"] = "Vitesse d'actualisation des flèches"
L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_HIGH"] = "Rapide"
L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_MEDIUM"] = "Moyen"
L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_REALTIME"] = "Temps réel"
L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_SLOW"] = "Lent"
L["S_MAPBAR_OPTIONSMENU_EQUIPMENTICONS"] = "Icônes d'équipement"
L["S_MAPBAR_OPTIONSMENU_QUESTTRACKER"] = "Activer le suivi de WQT"
L["S_MAPBAR_OPTIONSMENU_REFRESH"] = "Rafraichir"
L["S_MAPBAR_OPTIONSMENU_SOUNDENABLED"] = "Activer le son"
L["S_MAPBAR_OPTIONSMENU_STATUSBAR_ONDISABLE"] = "Utilisez la commande '/wqt statusbar' ou l'onglet \"addons\" dans \"menu: interface\" pour afficher à nouveau la barre d'info"
L["S_MAPBAR_OPTIONSMENU_STATUSBAR_VISIBILITY"] = "Afficher la barre d'info"
L["S_MAPBAR_OPTIONSMENU_STATUSBARANCHOR"] = "Attacher en  haut"
L["S_MAPBAR_OPTIONSMENU_TOMTOM_WPPERSISTENT"] = "Point de passage persistant"
L["S_MAPBAR_OPTIONSMENU_TRACKER_CURRENTZONE"] = "Zone actuelle seulement"
L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"] = "Échelle du Suivi : %s"
L["S_MAPBAR_OPTIONSMENU_TRACKERCONFIG"] = "Config du Suivi"
L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_AUTO"] = "Position automatique"
L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_CUSTOM"] = "Position personnalisée"
L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_LOCKED"] = "Verrouillé"
L["S_MAPBAR_OPTIONSMENU_UNTRACKQUESTS"] = "Arrêter tous les suivis"
L["S_MAPBAR_OPTIONSMENU_WORLDMAPCONFIG"] = "Config Carte du monde"
L["S_MAPBAR_OPTIONSMENU_YARDSDISTANCE"] = "Afficher la distance (mètres)"
L["S_MAPBAR_OPTIONSMENU_ZONE_QUESTSUMMARY"] = "Résumé des quêtes (plein écran)"
L["S_MAPBAR_OPTIONSMENU_ZONEMAPCONFIG"] = "Config Carte de zone"
L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"] = "Cliquez pour suivre toutes les quêtes: |cFFFFFFFF%s|r."
L["S_MAPBAR_SORTORDER"] = "Ordre de tri"
L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_FADE"] = "Quêtes transparentes"
L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"] = "Moins de %d heures"
L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_SHOWTEXT"] = "Texte temps restant"
L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_SORTBYTIME"] = "Trier par temps"
L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_TITLE"] = "Temps restant"
L["S_MAPBAR_SUMMARYMENU_ACCOUNTWIDE"] = "Tous vos perso."
--[[Translation missing --]]
--[[ L["S_OPTIONS_ACCESSIBILITY"] = ""--]] 
--[[Translation missing --]]
--[[ L["S_OPTIONS_ACCESSIBILITY_EXTRATRACKERMARK"] = ""--]] 
--[[Translation missing --]]
--[[ L["S_OPTIONS_ACCESSIBILITY_SHOWBOUNTYRING"] = ""--]] 
--[[Translation missing --]]
--[[ L["S_OPTIONS_ANIMATIONS"] = ""--]] 
L["S_OPTIONS_MAPFRAME_ALIGN"] = "Cadre de la carte centré"
L["S_OPTIONS_MAPFRAME_ERROR_SCALING_DISABLED"] = "Vous devez activer 'Echelle du cadre de la carte' avant, aucune valeur n'à changé"
L["S_OPTIONS_MAPFRAME_SCALE"] = [=[Échelle de la carte
]=]
L["S_OPTIONS_MAPFRAME_SCALE_ENABLED"] = "Activer la mise à l'échelle du cadre"
L["S_OPTIONS_QUESTBLACKLIST"] = "Liste noire de quêtes"
L["S_OPTIONS_RESET"] = "Réinitialiser"
L["S_OPTIONS_SHOWFACTIONS"] = "Afficher les factions"
L["S_OPTIONS_TIMELEFT_NOPRIORITY"] = "Pas de priorité par temps restant"
L["S_OPTIONS_TRACKER_RESETPOSITION"] = "Réinitialiser la position"
L["S_OPTIONS_WORLD_ANCHOR_LEFT"] = "Ancrer à gauche"
L["S_OPTIONS_WORLD_ANCHOR_RIGHT"] = "Ancrer à droite"
L["S_OPTIONS_WORLD_DECREASEICONSPERROW"] = "Diminuer le nombre de carrés par ligne"
L["S_OPTIONS_WORLD_INCREASEICONSPERROW"] = "Augmenter le nombre de carrés par ligne"
L["S_OPTIONS_WORLD_ORGANIZE_BYMAP"] = "Organiser par cartes"
L["S_OPTIONS_WORLD_ORGANIZE_BYTYPE"] = "Organiser par type de quête"
L["S_OPTIONS_ZONE_SHOWONLYTRACKED"] = "Seulement traqués"
L["S_OVERALL"] = "Total"
L["S_PARTY"] = "Groupe"
L["S_PARTY_DESC1"] = "Une étoile bleue veut dire que tous le groupe a la quête."
L["S_PARTY_DESC2"] = "Une étoile rouge veut dire qu'un membre du groupe ne peut pas faire cette quête ou n'a pas installé WQT."
L["S_PARTY_PLAYERSWITH"] = "Joueurs dans le groupe avec WQT :"
L["S_PARTY_PLAYERSWITHOUT"] = "Joueurs dans le groupe sans WQT :"
L["S_QUESTSCOMPLETED"] = "Quêtes terminées"
L["S_QUESTTYPE_ARTIFACTPOWER"] = "Puissance prodigieuse"
L["S_QUESTTYPE_DUNGEON"] = "Donjons"
L["S_QUESTTYPE_EQUIPMENT"] = "Équipement"
L["S_QUESTTYPE_GOLD"] = "Or"
L["S_QUESTTYPE_PETBATTLE"] = "Mascottes de combat"
L["S_QUESTTYPE_PROFESSION"] = "Profession"
L["S_QUESTTYPE_PVP"] = "JcJ"
L["S_QUESTTYPE_RESOURCE"] = "Ressources"
L["S_QUESTTYPE_TRADESKILL"] = "Artisanat"
L["S_RAREFINDER_ADDFROMPREMADE"] = "Ajouter les élites trouvés dans les groupes personnalisés. "
L["S_RAREFINDER_NPC_NOTREGISTERED"] = "élite non répertoriée"
L["S_RAREFINDER_OPTIONS_ENGLISHSEARCH"] = "Toujours chercher en anglais"
L["S_RAREFINDER_OPTIONS_SHOWICONS"] = "Afficher les icônes pour les élites en vie"
L["S_RAREFINDER_SOUND_ALWAYSPLAY"] = "Émettre un son même si les effets sonores sont désactivés"
L["S_RAREFINDER_SOUND_ENABLED"] = "Émettre un son en cas d'élite sur la minicarte."
L["S_RAREFINDER_SOUNDWARNING"] = "son émis à cause d'une élite sur la minicarte, vous pouvez le désactiver dans les options, puis élite tracker."
L["S_RAREFINDER_TITLE"] = "Élite tracker"
L["S_RAREFINDER_TOOLTIP_REMOVE"] = [=[Supprimer
]=]
L["S_RAREFINDER_TOOLTIP_SEACHREALM"] = "Chercher sur d'autres royaumes"
L["S_RAREFINDER_TOOLTIP_SPOTTEDBY"] = "Repéré par"
L["S_RAREFINDER_TOOLTIP_TIMEAGO"] = "il y a quelques minutes"
L["S_SUMMARYPANEL_EXPIRED"] = "EXPIRÉ"
L["S_SUMMARYPANEL_LAST15DAYS"] = "Les 15 derniers jours"
L["S_SUMMARYPANEL_LIFETIMESTATISTICS_ACCOUNT"] = "Statistiques de votre compte "
L["S_SUMMARYPANEL_LIFETIMESTATISTICS_CHARACTER"] = "Statistiques de votre personnage "
L["S_SUMMARYPANEL_OTHERCHARACTERS"] = "Autres personnages"
L["S_TUTORIAL_AMOUNT"] = "Indique le montant à recevoir"
L["S_TUTORIAL_CLICKTOTRACK"] = "Cliquez pour suivre une quête."
L["S_TUTORIAL_PARTY"] = "Dans un groupe, une étoile bleue indique les quêtes que tous le groupe fait !"
--[[Translation missing --]]
--[[ L["S_TUTORIAL_STATISTICS_BUTTON"] = ""--]] 
L["S_TUTORIAL_TIMELEFT"] = "Indique le temps restant (+4 heures, +90 minutes, +30 minutes, moins de 30 minutes)"
L["S_TUTORIAL_WORLDBUTTONS"] = [=[Cliquez ici pour alterner entre trois types de sommaires:

- |cFFFFAA11Par type de quête|r
- |cFFFFAA11Par zone|r
- |cFFFFAA11Aucun|r

Cliquez sur |cFFFFAA11Afficher les quêtes|r pour cacher les emplacements de quêtes.
]=]
L["S_TUTORIAL_WORLDMAPBUTTON"] = "Ce bouton vous apporte la carte des îles brisées."
L["S_UNKNOWNQUEST"] = "Quête inconnue"
--[[Translation missing --]]
--[[ L["S_WHATSNEW"] = ""--]] 
L["S_WORLDBUTTONS_SHOW_NONE"] = "Cacher le sommaire"
L["S_WORLDBUTTONS_SHOW_TYPE"] = "Afficher le sommaire"
L["S_WORLDBUTTONS_SHOW_ZONE"] = "Trier par zone"
L["S_WORLDBUTTONS_TOGGLE_QUESTS"] = "Activer les quêtes"
L["S_WORLDMAP_QUESTLOCATIONS"] = "Affiche les emplacements de quêtes"
L["S_WORLDMAP_QUESTSUMMARY"] = "Affiche les résumés de quêtes "
L["S_WORLDMAP_TOOGLEQUESTS"] = "Afficher les quêtes"
L["S_WORLDMAP_TOOLTIP_TRACKALL"] = "suivre toutes les quêtes de cette liste"
L["S_WORLDQUESTS"] = "Expéditions"

------------------------------------------------------------
--@localization(locale="frFR", format="lua_additive_table")@