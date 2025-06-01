#!/bin/bash

# Version améliorée des fonctions de sécurité

source "${SCRIPT_DIR}/src/security/validation.sh"

# Fonction pour vérifier la sécurité d'un script
check_script_security() {
    local script_path="$1"
    
    # Vérifier si le fichier existe
    if [[ ! -f "$script_path" ]]; then
        return 1
    fi
    
    # Vérifier les permissions
    if [[ ! -r "$script_path" ]]; then
        return 1
    fi
    
    # Vérifier que c'est bien un script shell
    if ! grep -q "^#\!/bin/\(ba\)\?sh" "$script_path"; then
        return 1
    fi
    
    # Vérifier le contenu du script
    if ! validate_basic_security "$(cat "$script_path")"; then
        return 1
    fi
    
    return 0
}
