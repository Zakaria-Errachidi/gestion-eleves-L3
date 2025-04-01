# Titre : Système de Gestion des Notes pour une Promotion

## Auteur

Nom : ERRACHIDI Zakaria

---

## Description

Ce projet est un script Bash permettant de gérer les notes des étudiants de L3 Informatique. Il offre plusieurs fonctionnalités pour manipuler et analyser les données académiques, telles que l'ajout, la suppression, le calcul des moyennes, et la validation des résultats.

---

## Fichiers

**main.sh** : Script principal contenant toutes les fonctionnalités.
**Notes.csv** : Fichier contenant les données des élèves et leurs notes.
**output.txt** : Fichier généré contenant les statistiques et résultats.

---

## Prérequis

Système d'exploitation : Linux ou macOS avec Bash.
**Dépendances : bc pour effectuer des calculs arithmétiques.**

---

## Utilisation

Exécutez le script avec la commande suivante :

./main.sh Notes.csv

---

## Fonctionnalités Principales

1. **Ajouter un élève** :

   - Demande le nom, le prénom et les 15 notes d’un étudiant.
   - Vérifie que chaque note est valide (entre 0 et 20).
   - Ajoute l’élève dans un fichier CSV.

2. **Supprimer un élève** :

   - Supprime un élève du fichier CSV en fonction de son nom et prénom.
   - Vérifie strictement la correspondance avec le fichier (sensible à la casse).

3. **Afficher les résultats** :

   - Calcule les moyennes pondérées pour chaque étudiant et pour la classe.
   - Génère un fichier de sortie (`output.txt`) contenant :
     - Les moyennes générales et par matière.
     - Les pourcentages de réussite.
     - Les modules problématiques.

4. **Statistiques générales** :
   - Calcule la moyenne générale de la classe.
   - Affiche les moyennes par matière et les performances globales.

---
