#!/bin/bash
# Surveillance basique des scripts (fonctionnalité additionnelle)

# Vérifier l'état d'un script
check_script_status() {
    local script_pid="$1"
    local script_name="$2"
    
    if ps -p "$script_pid" > /dev/null; then
        echo "✓ $script_name (PID: $script_pid) est en cours d'exécution"
        return 0
    else
        echo "✗ $script_name (PID: $script_pid) n'est pas en cours d'exécution"
        return 1
    fi
}

# Obtenir les statistiques basiques
get_script_stats() {
    local script_pid="$1"
    if [ -n "$script_pid" ]; then
        echo "Statistiques pour PID $script_pid:"
        ps -p "$script_pid" -o pid,ppid,%cpu,%mem,cmd
    fi
}

# Surveillance continue
monitor_script() {
    local script_pid="$1"
    local script_name="$2"
    local interval=5  # Intervalle en secondes
    
    while ps -p "$script_pid" > /dev/null; do
        get_script_stats "$script_pid"
        sleep "$interval"
    done
}

# Usage direct
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 {status|stats|monitor} PID [nom_script]"
    exit 1
fi

case "$1" in
    "status")
        check_script_status "$2" "$3"
        ;;
    "stats")
        get_script_stats "$2"
        ;;
    "monitor")
        monitor_script "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {status|stats|monitor} PID [nom_script]"
        exit 1
        ;;
esac
