#!/bin/bash

# BashOrchestrator - Gestionnaire intelligent de scripts Bash
# Version: 1.0

# Définition des variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
LOGS_DIR="${SCRIPT_DIR}/logs"
CONFIG_FILE="${CONFIG_DIR}/config.json"
LOG_FILE="${LOGS_DIR}/orchestrator.log"

# Définition des codes d'erreur
declare -r ERR_INVALID_OPTION=100
declare -r ERR_MISSING_PARAM=101
declare -r ERR_ADMIN_REQUIRED=102
declare -r ERR_EXECUTION_FAILED=103
declare -r ERR_INVALID_CONFIG=104

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS] [script]"
    echo ""
    echo "Options requises:"
    echo "  -h                    Affiche cette aide"
    echo "  -f                    Exécute en mode fork"
    echo "  -t                    Exécute en mode thread"
    echo "  -s                    Exécute en sous-shell"
    echo "  -l <dir>             Configure le répertoire des logs (admin)"
    echo "  -r                    Réinitialise la configuration (admin)"
    echo ""
    echo "Codes d'erreur:"
    echo "  100: Option invalide"
    echo "  101: Paramètre manquant"
    echo "  102: Privilèges administrateur requis"
    echo "  103: Échec de l'exécution"
    echo ""
    echo "Exemples:"
    echo "  $0 -h                        # Affiche l'aide"
    echo "  $0 -f script.sh             # Exécute avec fork"
    echo "  sudo $0 -r                   # Réinitialise (admin)"
}

# Fonction de logging
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d-%H-%M-%S')
    local username=$(whoami)
    local log_entry="${timestamp} : ${username} : ${level} : ${message}"
    
    # Log dans le fichier système si les permissions le permettent
    if [[ -w "/var/log/bashorchestrator" ]]; then
        echo "$log_entry" >> "/var/log/bashorchestrator/history.log"
    fi
    
    # Log dans le fichier local
    echo "$log_entry" >> "$LOG_FILE"
    
    # Affichage sur la sortie appropriée
    if [[ "$level" == "ERROR" ]]; then
        echo "$log_entry" >&2
    else
        echo "$log_entry"
    fi
}

# Fonction pour vérifier les dépendances
check_dependencies() {
    local deps=("jq" "cron")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "ERROR" "Dépendance manquante: $dep"
            exit 1
        fi
    done
}

# Fonction pour exécuter un script
run_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    local script_args="${@:2}"
    
    # Si le chemin n'est pas absolu, on le considère relatif à SCRIPTS_DIR
    if [[ ! "$script_path" = /* ]]; then
        script_path="${SCRIPTS_DIR}/${script_path}"
    fi
    
    # Validation de sécurité
    source "${SCRIPT_DIR}/scripts/security_enhanced.sh"
    
    # Nettoyer et valider le nom du script
    script_name=$(sanitize_input "$script_name" "argument")
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Nom de script invalide: $script_name"
        return $ERR_INVALID_CONFIG
    fi
    
    # Valider le chemin du script
    script_path=$(sanitize_input "$script_path" "path")
    if [[ $? -ne 0 || ! -f "$script_path" ]]; then
        log "ERROR" "Chemin de script invalide: $script_path"
        return $ERR_INVALID_CONFIG
    fi
    
    # Vérifier la sécurité du script
    if ! check_script_security "$script_path"; then
        log "ERROR" "Le script ne respecte pas les critères de sécurité"
        return $ERR_INVALID_CONFIG
    fi
    
    # Charger les limites de ressources depuis la configuration
    local mem_limit cpu_limit timeout
    if [[ -f "$CONFIG_FILE" ]]; then
        mem_limit=$(jq -r --arg name "$script_name" '.scripts[] | select(.name == $name) | .memory_limit // 80' "$CONFIG_FILE")
        cpu_limit=$(jq -r --arg name "$script_name" '.scripts[] | select(.name == $name) | .cpu_limit // 90' "$CONFIG_FILE")
        timeout=$(jq -r --arg name "$script_name" '.scripts[] | select(.name == $name) | .timeout // 3600' "$CONFIG_FILE")
    fi
    
    # Vérification des permissions
    chmod +x "$script_path"
    
    log "INFO" "Démarrage de l'exécution de $script_name en mode: ${EXECUTION_MODE:-normal}"
    
    local exit_code=0
    case "${EXECUTION_MODE:-normal}" in
        "fork")
            run_with_fork "$script_path" "$script_args"
            exit_code=$?
            ;;
        "thread")
            run_with_thread "$script_path" "$script_args"
            exit_code=$?
            ;;
        "subshell")
            run_with_subshell "$script_path" "$script_args"
            exit_code=$?
            ;;
        "normal"|"")
            # Exécution normale avec redirection des sorties et gestion des ressources
            (
                "$script_path" "$script_args" 2>&1 | tee -a "${LOGS_DIR}/${script_name}.log" &
                local script_pid=$!
                
                # Appliquer les limites de ressources
                source "${SCRIPT_DIR}/scripts/resource_manager.sh"
                limit_process_resources "$script_pid" "$mem_limit" "$cpu_limit" "$timeout"
                
                wait "$script_pid"
            )
            exit_code=${PIPESTATUS[0]}
            ;;
        *)
            log "ERROR" "Mode d'exécution non reconnu: $EXECUTION_MODE"
            return $ERR_INVALID_OPTION
            ;;
    esac
    
    if [[ $exit_code -eq 0 ]]; then
        log "SUCCESS" "Script $script_name exécuté avec succès"
    else
        log "ERROR" "Échec de l'exécution de $script_name (code: $exit_code)"
    fi
    
    return $exit_code
}

# Fonction pour lister les scripts configurés
list_scripts() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "INFO" "Aucun script configuré"
        return 0
    fi
    
    echo "Scripts configurés:"
    jq -r '.scripts[] | "- \(.name) [\(.schedule)] [\(.status)]"' "$CONFIG_FILE"
}

# Fonction pour configurer une tâche cron
setup_cron() {
    local script_name=$1
    local schedule=$2
    
    # Vérifier si le script existe
    if [[ ! -f "${SCRIPTS_DIR}/${script_name}" ]]; then
        log "ERROR" "Script non trouvé: $script_name"
        return 1
    fi
    
    # Créer la ligne crontab
    local cron_cmd="${schedule} ${SCRIPT_DIR}/orchestrator.sh -r ${script_name}"
    
    # Ajouter à crontab
    (crontab -l 2>/dev/null | grep -v "${script_name}"; echo "$cron_cmd") | crontab -
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Tâche cron configurée pour $script_name"
        return 0
    else
        log "ERROR" "Échec de la configuration cron pour $script_name"
        return 1
    fi
}

# Fonction pour configurer toutes les tâches cron depuis le fichier de configuration
setup_all_crons() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR" "Fichier de configuration non trouvé"
        return 1
    fi
    
    local scripts=$(jq -r '.scripts[] | select(.status == "enabled") | "\(.name)|\(.schedule)"' "$CONFIG_FILE")
    
    while IFS="|" read -r name schedule; do
        if [[ -n "$name" && -n "$schedule" ]]; then
            setup_cron "$name" "$schedule"
        fi
    done <<< "$scripts"
}

# Fonction pour configurer les logs système
setup_system_logs() {
    # Vérification des privilèges admin
    if ! check_admin; then
        log "ERROR" "Privilèges administrateur requis pour configurer les logs système"
        return $ERR_ADMIN_REQUIRED
    fi
    
    # Création du répertoire de logs système
    local system_log_dir="/var/log/bashorchestrator"
    if [[ ! -d "$system_log_dir" ]]; then
        mkdir -p "$system_log_dir"
        chmod 755 "$system_log_dir"
    fi
    
    # Configuration du fichier de log
    touch "$system_log_dir/history.log"
    chmod 644 "$system_log_dir/history.log"
    chown root:root "$system_log_dir/history.log"
    
    return 0
}

# Initialisation
init() {
    # Création des répertoires nécessaires s'ils n'existent pas
    mkdir -p "$CONFIG_DIR" "$SCRIPTS_DIR" "$LOGS_DIR"
    
    # Création du fichier de configuration s'il n'existe pas
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo '{"scripts":[]}' > "$CONFIG_FILE"
    fi
    
    # Vérification des permissions locales
    chmod 755 "$SCRIPTS_DIR"
    chmod 644 "$CONFIG_FILE"
    chmod 755 "$LOGS_DIR"
    
    # Configuration des logs système si on est root
    if check_admin; then
        setup_system_logs
    fi
    
    # Utilisation du répertoire de log personnalisé si spécifié
    if [[ -n "$LOG_DIR" ]]; then
        if [[ ! -d "$LOG_DIR" ]]; then
            mkdir -p "$LOG_DIR"
        fi
        LOGS_DIR="$LOG_DIR"
    fi
}

# Variables globales pour les modes d'exécution
EXECUTION_MODE=""
LOG_DIR=""

# Programme principal
main() {
    # Source des scripts externes au début pour les rendre disponibles partout
    source "${SCRIPT_DIR}/scripts/admin_check.sh"
    source "${SCRIPT_DIR}/scripts/process_manager.sh"
    source "${SCRIPT_DIR}/src/security/validation.sh"
    
    check_dependencies
    init
    
    # Vérification qu'au moins une option est fournie
    if [[ $# -eq 0 ]]; then
        log "ERROR" "Au moins une option est requise"
        show_help
        exit $ERR_MISSING_PARAM
    fi
    
    # Traitement des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--fork)
                EXECUTION_MODE="fork"
                shift
                if [[ -n "$1" ]]; then
                    run_script "$1" "${@:2}"
                    exit $?
                fi
                ;;
            -t|--thread)
                EXECUTION_MODE="thread"
                shift
                if [[ -n "$1" ]]; then
                    run_script "$1" "${@:2}"
                    exit $?
                fi
                ;;
            -s|--subshell)
                EXECUTION_MODE="subshell"
                shift
                if [[ -n "$1" ]]; then
                    run_script "$1" "${@:2}"
                    exit $?
                fi
                ;;
            -l|--log)
                if requires_admin "-l" && ! check_admin; then
                    log "ERROR" "Privilèges administrateur requis pour cette option"
                    exit $ERR_ADMIN_REQUIRED
                fi
                if [[ -n "$2" ]]; then
                    LOG_DIR="$2"
                    shift 2
                else
                    log "ERROR" "Répertoire de log manquant"
                    exit $ERR_MISSING_PARAM
                fi
                ;;
            -r|--restore)
                if requires_admin "-r" && ! check_admin; then
                    log "ERROR" "Privilèges administrateur requis pour cette option"
                    exit $ERR_ADMIN_REQUIRED
                fi
                # Charger le gestionnaire de restauration
                source "${SCRIPT_DIR}/scripts/restore_manager.sh"
                
                if restore_defaults "$CONFIG_FILE" "$SCRIPT_DIR"; then
                    log "SUCCESS" "Paramètres réinitialisés avec succès"
                    init
                else
                    log "ERROR" "Échec de la réinitialisation, tentative de restauration"
                    if rollback_restore "$CONFIG_FILE" "$SCRIPT_DIR"; then
                        log "INFO" "Restauration du backup réussie"
                    else
                        log "ERROR" "Échec de la restauration du backup"
                    fi
                    exit $ERR_EXECUTION_FAILED
                fi
                exit 0
                ;;
            --monitor)
                source "${SCRIPT_DIR}/scripts/monitor.sh"
                if [[ -n "$2" && -n "$3" ]]; then
                    "${SCRIPT_DIR}/scripts/monitor.sh" "$2" "$3"
                    exit $?
                else
                    log "ERROR" "Action et PID requis pour le monitoring"
                    exit $ERR_MISSING_PARAM
                fi
                ;;
            --report)
                if [[ -n "$2" ]]; then
                    "${SCRIPT_DIR}/scripts/report.sh" "$2"
                    exit $?
                else
                    log "ERROR" "Nom du script requis pour le rapport"
                    exit $ERR_MISSING_PARAM
                fi
                ;;
            *)
                log "ERROR" "Option invalide: $1"
                show_help
                exit $ERR_INVALID_OPTION
                ;;
        esac
        shift
    done
    
    show_help
}

main "$@"
