#!/bin/bash

# Module de vérification des privilèges administrateur simplifié
# Selon le cahier des charges: seuls -l et -r requièrent les privilèges admin

check_admin() {
    if [ "$(id -u)" != "0" ]; then
        echo "ERREUR: Cette opération nécessite les privilèges administrateur."
        echo "Utilisez 'sudo $0' pour exécuter cette commande."
        return 1
    fi
    return 0
}

# Vérifie si une option nécessite des droits admin
requires_admin() {
    case "$1" in
        "-l"|"-r")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
