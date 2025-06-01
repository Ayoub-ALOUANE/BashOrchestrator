#!/bin/bash

# Test des trois scénarios requis par le cahier des charges
# Léger / Moyen / Lourd avec les trois modes d'exécution

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/../orchestrator.sh"

# Fonction pour exécuter un test et mesurer le temps
run_test() {
    local mode=$1
    local load=$2
    local start_time
    local end_time
    
    echo "=== Test $load avec mode $mode ==="
    start_time=$(date +%s.%N)
    "$MAIN_SCRIPT" "$mode" "test_modes.sh" "$load"
    end_time=$(date +%s.%N)
    
    echo "Temps d'exécution: $(echo "$end_time - $start_time" | bc) secondes"
    echo "----------------------------------------"
}

# Tests en mode fork
echo "### Tests en mode fork (-f) ###"
run_test "-f" "light"
run_test "-f" "medium"
run_test "-f" "heavy"

# Tests en mode thread
echo "### Tests en mode thread (-t) ###"
run_test "-t" "light"
run_test "-t" "medium"
run_test "-t" "heavy"

# Tests en mode subshell
echo "### Tests en mode subshell (-s) ###"
run_test "-s" "light"
run_test "-s" "medium"
run_test "-s" "heavy"
