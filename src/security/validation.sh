#!/bin/bash
# Module de validation basique conforme au cahier des charges

# Commandes critiques interdites
RESTRICTED_COMMANDS=(
    "rm -rf /"
    "mkfs"
    "dd"
    "chmod -R 777"
)

# Chemins système protégés (uniquement ceux nécessaires)
PROTECTED_PATHS=(
    "/var/log/bashorchestrator"  # Seul chemin système requis par le cahier des charges
)

# Fonction pour nettoyer et valider les entrées
sanitize_input() {
    local input="$1"
    local type="$2"
    
    case "$type" in
        "argument")
            # Nettoyage basique pour les arguments
            echo "$input" | sed 's/[^a-zA-Z0-9_.-]//g'
            ;;
        "path")
            # Nettoyage pour les chemins
            echo "$input" | sed 's/[^a-zA-Z0-9/_.-]//g'
            ;;
        *)
            return 1
            ;;
    esac
    
    return 0
}

# Validation basique de sécurité
validate_basic_security() {
    local cmd="$1"
    
    # Vérification des commandes interdites
    for restricted in "${RESTRICTED_COMMANDS[@]}"; do
        if [[ "$cmd" == *"$restricted"* ]]; then
            echo "ERREUR: Commande interdite détectée"
            return 1
        fi
    done
    
    log "INFO" "Security initialized at $level level"
    return 0
}

# Validate command for security
validate_command() {
    local cmd="$1"
    
    # Check restricted commands
    for restricted in "${RESTRICTED_COMMANDS[@]}"; do
        if [[ "$cmd" == *"$restricted"* ]]; then
            log "ERROR" "Restricted command detected: $cmd"
            return 1
        fi
    done
    
    # Vérification des chemins protégés pour les options -l et -r
    if [[ "$cmd" == *"/var/log/bashorchestrator"* ]] && [ "$(id -u)" != "0" ]; then
        echo "ERREUR: Accès refusé - privilèges administrateur requis"
        return 1
    fi
    
    return 0
}

# Validation basique des entrées
check_input() {
    local input="$1"
    
    # Vérification basique des caractères autorisés
    if ! echo "$input" | grep -q '^[a-zA-Z0-9/_.-]\+$'; then
        echo "ERREUR: Caractères non autorisés détectés"
        return 1
    fi
    
    return 0
}

# Vérification des permissions de base
check_file_permissions() {
    local file="$1"
    
    # Vérification simple des permissions excessives
    if [ -f "$file" ]; then
        local perms=$(stat -c "%a" "$file")
        if [[ "$perms" == "777" ]]; then
            chmod 755 "$file"
        fi
    fi
    
    return 0
}
