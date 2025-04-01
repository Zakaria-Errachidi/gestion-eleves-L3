#!/bin/bash
function ajouter_eleve() {
    fichier="$1"

    #demander les informations debase pour identifier l'élève 
    echo "Entrez le nom de l'élève :"
    read nom
    echo "Entrez le prénom de l'élève :"
    read prenom

    #une boucle pour saisir les 15 notes de l'élève.
    declare -a notes
    for (( i=1; i<=15; i++ ))
    do
        while true; do
            echo "Entrez la note $i (entre 0 et 20) :"
            read note
            # Vérifier que la note est un nombre entre 0 et 20
            if  (( $(echo "$note >= 0 && $note <= 20" | bc -l) )) && [[ "$note" =~ ^[0-9]+(\.[0-9]+)?$ ]]
            then
                notes+=("$note")
                break
            else
                echo " Note invalide. Veuillez saisir une valeur entre 0 et 20 "
            fi
        done
    done

    #ajouter l'élève au fichier
    notes_str=$(IFS=','; echo "${notes[*]}")

    nv_ligne="$nom,$prenom,$notes_str"
    echo "$nv_ligne" >> "$fichier"
    echo "Vous avez bien ajouté L'élève $nom $prenom avec succès."
}

function supprimer_eleve() {
    fichier="$1"

    # Demander le nom et le prénom de l'élève
    echo "Entrez le nom de l'élève à supprimer :"
    read nom
    echo "Entrez le prénom de l'élève à supprimer :"
    read prenom

    # supprimer l'élève correspondant en écrivant les autres lignes dans un fichier temporaire
    tmp_file=$(mktemp)
    grep -v "^$nom,$prenom," "$fichier" > "$tmp_file"

    if cmp -s "$fichier" "$tmp_file"; then
        echo "L'élève $nom $prenom n'a pas été trouvé."
    else
        mv "$tmp_file" "$fichier"
        echo "L'élève $nom $prenom a été supprimé avec succès."
    fi
    rm -f "$tmp_file"  # Nettoyage du fichier temporaire
}


function calcule_moyenne(){
        notes=("$@")
        coeffs=(7 2 4 3 6 7 5 3 3 2 2 4 3 3 6)
        total=0
        total_coeff=0


        for i in "${!notes[@]}"
        do
                note=${notes[i]}
                coeff=${coeffs[i]}
                # Vérifie si la note est vide ou non numérique, si invalide retourne une erreur et interrompt le calcul
                if [[ -z "$note" || ! "$note" =~ ^[0-9]+(\.[0-9]+)?$ ]]
                then
                        echo "Erreur : Note invalide '$note' à la position $((i + 1))."
                        return 1
                fi
                total=$(echo "$total + $note * $coeff" | bc 2>/dev/null)
                total_coeff=$(echo "$total_coeff + $coeff" | bc 2>/dev/null)
        done

        if [ "$total_coeff" -gt 0 ]
        then
                moyenne=$(echo "scale=2; $total / $total_coeff" | bc 2>/dev/null)
        else
                moyenne=0.00
        fi
        echo "$moyenne"
}

function valider_recursive() {
    moyenne="$1"          # La moyenne est le premier paramètre
    shift                 # Supprime la moyenne des arguments
    local competences=("$@")   # Récupère les competences restants (C1, C2, ...)

    # Vérifie la moyenne (condition de base pour validation)
    if (( $(echo "$moyenne < 10" | bc -l) )); then
        echo "Non Validé"
        return
    fi

    # Condition d'arrêt : plus de competences à vérifier
    if [ ${#competences[@]} -eq 0 ]
    then
        echo "Validé"
        return
    fi

    # Vérifie la premiere competence
    local competence="${competences[0]}"
    if (( $(echo "$competence < 8" | bc -l) ))
    then
        echo "Non Validé"
        return
    fi

    # Appel récursif pour vérifier les competences restants
    valider_recursive "$moyenne" "${competences[@]:1}"
}

#fonction qui calcule le pourcentage des eleves pour qu'on l'affiche dans stats generale
function pourcentage_reussite(){
        total_eleves="$1"
        eleves_valides="$2"
        if [ "$total_eleves" -gt 0 ]
        then
                pourcentage=$(echo "scale=2; ($eleves_valides / $total_eleves) * 100" | bc)
        else
                pourcentage=0
        fi
        
        echo "                                                                                   Pourcentage de réussite : $pourcentage%"
}

#fonction pour avoir la meme format des message d'erreur
function afficher_erreur() {
    message="$1"
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------" >> "$fichier_sortie"
    echo "| Erreur : $message" >> "$fichier_sortie"
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------" >> "$fichier_sortie"
}

function afficher_notes(){
        mon_fichier="$1"
        fichier_sortie="$2"
        #initialiser
        ((cpt=-1)) #pour ne pas prendre la premiere ligne "le header"
        declare -a moyennes_eleves
        declare -a total_matieres=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
        total_eleves=0
        eleves_valides=0
        # Variables pour accumuler les notes

        #verifier l'existance du fichier
        if [ ! -e "$mon_fichier" ] || [ ! -s "$mon_fichier" ]
        then
                echo " le fichier $mon_fichier que vous avez mis n'existe pas"
                exit 1
        fi

        #en tete du fichier de sortie
        echo "=================================================================================================================================================================================================================" > "$fichier_sortie"
        echo "                                                                                                 Résultats des Élèves                                                                                       " >> "$fichier_sortie"
        echo "=================================================================================================================================================================================================================" >> "$fichier_sortie"
        echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"  >> "$fichier_sortie"
        echo "|  Elève               | THLAN | OLOGI | COOBJ | PWEB2 | ALGO5 | CAVAC | LCPFO | Shell | Arch3 | S.A.E | S.A.E | S.A.E |  Ang5 |  Ang6 | Stage |   C1  |   C2  |   C3  |   C4  |   C5  | Moyenne   |             |"  >> "$fichier_sortie"
        echo "|                      |       |       |       |       |       |       |       |       |       | SHELL | PWEB2 |  T.E  |       |       |       |  (16) |  (18) |  (6)  |  (8)  |  (12) | generale  |             |" >> "$fichier_sortie"
        echo " ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------" >> "$fichier_sortie"
        
        #parcourir les lignes du fichier d'entree
        IFS=$'\n'
        for line in $(cat "$mon_fichier")
        do
                ((cpt++))
                if ((cpt == 0))
                then
                        continue
                fi

                #ignorer les lignes vides du fichier d'entrée pour éviter les erreurs.
                if [[ -z "$line" ]]
                then
                        continue
                fi

                IFS=','
                read -a entete <<< ${line}  #lire les headers et les affecte

                if [[ -z "${entete[0]}" || -z "${entete[1]}" ]]
                then
                        continue
                fi

                #etraire les notes (colonnes 3 à 17)
                notes=("${entete[@]:2:15}")
                # Vérifier si le nombre de notes est insuffisant, compléter avec des 0 si nécessaire
                if (( ${#notes[@]} < 15 ))
                then
                afficher_erreur " Avertissement : données incomplètes pour ${entete[0]} ${entete[1]}. Complétion avec des 0." >> "$fichier_sortie"
                while (( ${#notes[@]} < 15 ))
                do
                        notes+=(0)
                done
                fi

                #on initialise la validite de notes a false
                invalid=false 
                # Remplacer les valeurs vides par 0
                for i in "${!notes[@]}"
                do
                        if [[ -z "${notes[i]}" || "${notes[i]}" =~ ^[a-zA-Z]+$ || "${notes[i]}" =~ ^.*[^0-9.].*$ ]]
                        then
                                notes[i]=0
                        fi
                done

                # Validation des note
                for note in "${notes[@]}"
                do
                        #Bash ne peut pas traiter les nombres décimaux dans les expressions arithmétiques (comme 12.5).j'ignore cette erreur en la redirigeant vers /dev/null
                        if [[ -z "$note" || "$note" -lt 0 || "$note" -gt 20 ]] 2>/dev/null
                        then
                                invalid=true
                                break
                        fi
                done

                #ignorer la ligne si la une note invalide
                if [ "$invalid" = true ]
                then
                        afficher_erreur " Ligne ignorée pour l'eleve ${entete[0]} ${entete[1]} : notes invalides essayer de corriger la note sur ton fichier" >> "$fichier_sortie"
                        continue
                fi

                #calculer la moyenne generale
                moyenne=$(calcule_moyenne "${notes[@]}")
                moyennes_eleves+=("$moyenne")
                moyenne=$(calcule_moyenne "${notes[@]}")


                #calculer la moyenne pour chaque competence
                C1=$(echo "scale=2; (${notes[0]}*7 + ${notes[1]}*2 + ${notes[2]}*4 + ${notes[3]}*3) / 16" | bc 2>/dev/null)
                C2=$(echo "scale=2; (${notes[4]}*6 + ${notes[5]}*7 + ${notes[6]}*5) / 18" | bc 2>/dev/null)
                C3=$(echo "scale=2; (${notes[7]}*3 + ${notes[8]}*3) / 6" | bc 2>/dev/null)
                C4=$(echo "scale=2; (${notes[9]}*2 + ${notes[10]}*2 + ${notes[11]}*4) / 8" | bc 2>/dev/null)
                C5=$(echo "scale=2; (${notes[12]}*3 + ${notes[13]}*3 + ${notes[14]}*6) / 12" | bc 2>/dev/null)

                #mise à jour des totaux pour chaque matière
                for i in "${!notes[@]}"
                do
                        total_matieres[$i]=$(echo "${total_matieres[$i]} + ${notes[$i]}" | bc)
                done
                #incrementer le nbre total d'eleve
                total_eleves=$((total_eleves + 1))

                # Appel à la fonction de validation
                validation_result=$(valider_recursive "$moyenne" "$C1" "$C2" "$C3" "$C4" "$C5")
                if [[ "$validation_result" == "Validé" ]]
                then
                        ((eleves_valides++))  # Incrémenter les élèves validés
                fi

                #pour un faire un affichage clair
                printf "| %-20s | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %5.2f | %9.2f | %12s |\n" "${entete[0]} ${entete[1]}" "${entete[2]}" "${entete[3]}" "${entete[4]}" "${entete[5]}" "${entete[6]}" "${entete[7]}" "${entete[8]}" "${entete[9]}" "${entete[10]}" "${entete[11]}" "${entete[12]}" "${entete[13]}" "${entete[14]}" "${entete[15]}" "${entete[16]}" "$C1" "$C2" "$C3" "$C4" "$C5" "$moyenne" "$validation_result" >> "$fichier_sortie" 2>/dev/null
        done
        
        #appeler la fonction affiche stats pour afficher les stats de la promo
        afficher_stats "$fichier_sortie" "$total_eleves" "${total_matieres[@]}" "$eleves_valides"

}

function afficher_stats(){
        fichier_sortie="$1"
        total_eleve="$2"
        total_matieres=("${@:3}")
        matieres=("THLAN" "OLOGI" "COO" "PWEB2" "ALGO5" "CAVAC" "LCPFO" "Shell" "Arch3" "SAE Shell" "SAE PWEB2" "SAE TE" "Ang5" "Ang6" "Stage")

        #s'il existe au moins un eleve calcule la moyenne
        if [ "$total_eleve" -gt 0 ]
        then
                for i in "${!total_matieres[@]}"
                do
                        # Calcul de la moyenne pour chaque matière
                        moyennes[$i]=$(echo "scale=2; ${total_matieres[$i]} / $total_eleve" | bc)
                done

                # Calcul de la moyenne générale pondérée de la classe
                moyenne_generale_classe=$(echo "scale=2; ($(IFS=+; echo "${total_matieres[*]}")) / ($total_eleve * 15)" | bc)

                if [ ${#moyennes_eleves[@]} -gt 0 ]
                then
                        somme_moyennes=0
                        for moyenne in "${moyennes_eleves[@]}"
                        do
                                somme_moyennes=$(echo "$somme_moyennes + $moyenne" | bc)
                        done
                        # Calcul de la moyenne générale basée sur les moyennes des élèves
                        moyenne_generale_classe=$(echo "scale=2; $somme_moyennes / ${#moyennes_eleves[@]}" | bc)
                else
                        moyenne_generale_classe=0.00
                fi
        else
            for i in "${!total_matieres[@]}"
            do
                    moyennes[$i]=00.00
            done

            moyenne_generale_classe=00.00
        fi

        # Écriture des statistiques générales dans le fichier de sortie
        cat <<-STATS >> "$fichier_sortie"

=================================================================================================================================================================================================================
                                                                                    Statistiques Générales
=================================================================================================================================================================================================================
STATS
        
        # Affichage des moyennes pour chaque matière
        for i in "${!matieres[@]}"
        do
            echo "                                                                                  Moyenne pour ${matieres[$i]} : ${moyennes[$i]}/20" >> "$fichier_sortie"
        done
        echo "                                                         -------------------------------------------------------------------------------" >> "$fichier_sortie"
        
        #si la moyenne est valide on l'affiche direct sinon on recalcule la moyenne a partir des moyennes des matieres
        if [[ $moyenne_generale_classe =~ ^[0-9]+(\.[0-9]+)?$ ]]
        then
                echo "                                                                               Moyenne générale de la classe : $moyenne_generale_classe / 20" >> "$fichier_sortie"
        else
                somme=0
                for i in "${!matieres[@]}"
                do
                        somme=$(echo "$somme + ${moyennes[$i]}" | bc)
                done
                nv_moyenne=$(echo "scale=2; $somme / 15" | bc)
                echo "                                                                               Moyenne générale de la classe : $nv_moyenne / 20" >> "$fichier_sortie"
        fi

        #appeler la fonction pourcentage pour afficher le pourcentage de reussite dans les stats generale
        pourcentage_reussite "$total_eleve" "$eleves_valides" >> "$fichier_sortie"
        echo "=================================================================================================================================================================================================================" >> "$fichier_sortie"
}


function main(){
        # Vérifie si le script est exécuté avec un fichier en paramètre.
        if [ $# -ne 1 ]
        then
                echo "Usage : $0 <nom_du_fichier>"
                exit 1
        fi
        mon_fichier="$1"
        echo "Sélectionnez une option :"

        echo "1. Ajouter un élève"

        echo "2. Supprimer un élève"

        echo "3. Afficher les résultats des élèves"

        read -p "Votre choix : " choix
        case $choix in
                1) ajouter_eleve "$mon_fichier" ;;
                2) supprimer_eleve "$mon_fichier" ;;
                3)
                        fichier_sortie="output.txt"
                        afficher_notes "$mon_fichier" "$fichier_sortie"
                        echo "Les résultats ont été enregistrés dans $fichier_sortie."
                        ;;
                *)
                        echo "Option invalide. Veuillez choisir 1, 2 ou 3."
                        ;;
        esac



}
main "$@"