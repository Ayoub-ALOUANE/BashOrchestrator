#!/bin/bash
# Gestionnaire de processus - Implémentation minimale des 3 modes requis

# Mode Fork (-f)
run_with_fork() {
    local script="$1"
    shift
    if [ ! -f "$script" ]; then
        echo "Erreur: Script '$script' non trouvé"
        return 1
    fi
    echo "Exécution en mode fork: $script"
    (exec "$script" "$@") &
    wait $!
    return $?
}

# Mode Thread (-t)
run_with_thread() {
    local script="$1"
    shift
    # Implémentation basique avec &
    "$script" "$@" &
    wait $!
    return $?
    
    # Nombre de cœurs CPU disponibles
    local cpu_cores=$(nproc)
    
    # Configuration de GNU Parallel
    export PARALLEL_HOME="${CONFIG_DIR}/parallel"
    mkdir -p "$PARALLEL_HOME"
    
    # Exécution avec GNU Parallel
    parallel --jobs "$cpu_cores" --line-buffer \
        --joblog "${LOGS_DIR}/parallel_job.log" \
        --progress \
        "$script_path {}" ::: "$script_args"
    
    return $?
}

# Mode Subshell (-s)
run_with_subshell() {
    local script="$1"
    shift
    (
        bash -c "exec $script $*"
    )
    return $?
}

# Fonction simple de dépendance (fonctionnalité additionnelle)
check_dependency() {
    local script="$1"
    local depends_on="$2"
    
    if [ ! -f "$script" ]; then
        echo "Erreur: Script '$script' non trouvé"
        return 1
    fi
    
    if [ -n "$depends_on" ] && [ ! -f "$depends_on" ]; then
        echo "Erreur: Dépendance '$depends_on' non trouvée"
        return 1
    fi
    
    if [ -n "$depends_on" ]; then
        # Exécuter d'abord la dépendance
        "$depends_on"
        local status=$?
        if [ $status -ne 0 ]; then
            echo "Erreur: La dépendance a échoué"
            return $status
        fi
    fi
    
    return 0
}

# Planification simple (fonctionnalité additionnelle)
schedule_script() {
    local script="$1"
    local delay="$2"  # Délai en minutes
    
    if [ ! -f "$script" ]; then
        echo "Erreur: Script '$script' non trouvé"
        return 1
    fi
    
    echo "Planification de $script dans $delay minutes"
    (
        sleep $((delay * 60))
        ./"$script"
    ) &
    
    echo "PID de la planification: $!"
    return 0
}

# Fonction principale d'exécution
execute_script() {
    local mode="$1"
    local script="$2"
    shift 2
    
    case "$mode" in
        "fork")
            run_with_fork "$script" "$@"
            ;;
        "thread")
            run_with_thread "$script" "$@"
            ;;
        "subshell")
            run_with_subshell "$script" "$@"
            ;;
        *)
            echo "Mode d'exécution non reconnu"
            return 1
            ;;
    esac
    return $?
}
