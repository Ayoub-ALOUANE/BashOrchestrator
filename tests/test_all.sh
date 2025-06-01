#!/bin/bash
# Test automatisé complet de BashOrchestrator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PARENT_DIR}/logs/test_results.log"

log_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $test_name: $status - $message" | tee -a "$LOG_FILE"
}

run_test() {
    local test_name="$1"
    local cmd="$2"
    echo "=== Exécution du test: $test_name ==="
    if eval "$cmd"; then
        log_test "$test_name" "SUCCESS" "Test réussi"
        return 0
    else
        log_test "$test_name" "FAILURE" "Test échoué"
        return 1
    fi
}

# 1. Tests des modes d'exécution
test_execution_modes() {
    echo "=== Tests des modes d'exécution ==="
    
    run_test "Mode Fork" "${PARENT_DIR}/orchestrator.sh -f test_light.sh"
    run_test "Mode Thread" "${PARENT_DIR}/orchestrator.sh -t test_light.sh"
    run_test "Mode Subshell" "${PARENT_DIR}/orchestrator.sh -s test_light.sh"
}

# 2. Tests des scénarios de charge
test_scenarios() {
    echo "=== Tests des scénarios de charge ==="
    
    run_test "Scénario Léger" "${PARENT_DIR}/orchestrator.sh -f test_light.sh"
    run_test "Scénario Moyen" "${PARENT_DIR}/orchestrator.sh -f test_medium.sh"
    run_test "Scénario Lourd" "${PARENT_DIR}/orchestrator.sh -f test_heavy.sh"
}

# 3. Tests du monitoring
test_monitoring() {
    echo "=== Tests du monitoring ==="
    
    # Lancer un script en arrière-plan pour le monitoring
    ${PARENT_DIR}/orchestrator.sh -f test_medium.sh &
    local pid=$!
    sleep 2
    
    run_test "Monitoring Status" "${PARENT_DIR}/scripts/monitor.sh status $pid test_medium"
    run_test "Monitoring Stats" "${PARENT_DIR}/scripts/monitor.sh stats $pid"
    
    wait $pid
}

# 4. Tests des notifications
test_notifications() {
    echo "=== Tests des notifications ==="
    
    run_test "Notification Info" "${PARENT_DIR}/scripts/notify.sh 'Test notification info' INFO"
    run_test "Notification Warning" "${PARENT_DIR}/scripts/notify.sh 'Test notification warning' WARNING"
    run_test "Notification Error" "${PARENT_DIR}/scripts/notify.sh 'Test notification error' ERROR"
}

# 5. Tests des rapports
test_reports() {
    echo "=== Tests de génération des rapports ==="
    
    run_test "Génération Rapport" "${PARENT_DIR}/scripts/report.sh test_light.sh"
}

# 6. Test du script combiné
test_combined() {
    echo "=== Test du scénario combiné ==="
    
    run_test "Script Combiné" "${PARENT_DIR}/scripts/test_combined.sh"
}

# Exécution de tous les tests
main() {
    echo "=== Début des tests automatisés ==="
    echo "Date: $(date)"
    echo "---"
    
    test_execution_modes
    test_scenarios
    test_monitoring
    test_notifications
    test_reports
    test_combined
    
    echo "=== Fin des tests automatisés ==="
    echo "Consultez ${LOG_FILE} pour les résultats détaillés"
}

# Créer le répertoire de logs si nécessaire
mkdir -p "$(dirname "$LOG_FILE")"

# Lancer les tests
main
