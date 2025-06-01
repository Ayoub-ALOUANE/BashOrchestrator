#!/bin/bash
# Tests complets pour BashOrchestrator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PARENT_DIR}/logs/test_results_detailed.log"
SCENARIOS_DIR="${SCRIPT_DIR}/scenarios"

# Fonction de logging
log_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $test_name: $status - $message" | tee -a "$LOG_FILE"
}

# Fonction d'assertion
assert() {
    local condition="$1"
    local message="$2"
    if eval "$condition"; then
        log_test "${FUNCNAME[1]}" "SUCCESS" "$message"
        return 0
    else
        log_test "${FUNCNAME[1]}" "FAILURE" "$message"
        return 1
    fi
}

# 1. Tests du Cahier des Charges
test_required_options() {
    echo "=== Test des options obligatoires ==="
    
    # Test -h
    assert "$PARENT_DIR/orchestrator.sh -h 2>&1 | grep -q 'Usage'" \
          "Option -h : Affichage de l'aide"
    
    # Test -f
    assert "$PARENT_DIR/orchestrator.sh -f ${SCENARIOS_DIR}/test_light.sh" \
          "Option -f : Mode fork"
    
    # Test -t
    assert "$PARENT_DIR/orchestrator.sh -t ${SCENARIOS_DIR}/test_light.sh" \
          "Option -t : Mode thread"
    
    # Test -s
    assert "$PARENT_DIR/orchestrator.sh -s ${SCENARIOS_DIR}/test_light.sh" \
          "Option -s : Mode sous-shell"
    
    # Test -l (admin)
    assert "sudo $PARENT_DIR/orchestrator.sh -l /var/log/bashorchestrator" \
          "Option -l : Configuration des logs (admin)"
    
    # Test -r (admin)
    assert "sudo $PARENT_DIR/orchestrator.sh -r" \
          "Option -r : Réinitialisation (admin)"
}

# 2. Tests des Scénarios
test_scenarios() {
    echo "=== Test des scénarios ==="
    
    # Test léger
    assert "$PARENT_DIR/orchestrator.sh -f ${SCENARIOS_DIR}/test_light.sh" \
          "Scénario léger"
    
    # Test moyen
    assert "$PARENT_DIR/orchestrator.sh -t ${SCENARIOS_DIR}/test_medium.sh" \
          "Scénario moyen"
    
    # Test lourd
    assert "$PARENT_DIR/orchestrator.sh -s ${SCENARIOS_DIR}/test_heavy.sh" \
          "Scénario lourd"
}

# 3. Tests de Sécurité
test_security() {
    echo "=== Test des fonctionnalités de sécurité ==="
    
    # Test des privilèges admin
    assert "! $PARENT_DIR/orchestrator.sh -l /etc 2>&1 | grep -q 'SUCCESS'" \
          "Contrôle des privilèges admin"
    
    # Test validation des entrées
    assert "! $PARENT_DIR/orchestrator.sh -f '../etc/passwd' 2>&1 | grep -q 'SUCCESS'" \
          "Validation des chemins"
    
    # Test protection commandes dangereuses
    assert "! $PARENT_DIR/orchestrator.sh -f 'rm -rf /' 2>&1 | grep -q 'SUCCESS'" \
          "Protection contre les commandes dangereuses"
}

# 4. Tests de la Valeur Ajoutée
test_added_features() {
    echo "=== Test des fonctionnalités additionnelles ==="
    
    # Test monitoring
    $PARENT_DIR/orchestrator.sh -f "${SCENARIOS_DIR}/test_medium.sh" &
    pid=$!
    sleep 2
    
    assert "$PARENT_DIR/scripts/monitor.sh status $pid" \
          "Monitoring - Statut"
    
    assert "$PARENT_DIR/scripts/monitor.sh stats $pid" \
          "Monitoring - Statistiques"
    
    wait $pid
    
    # Test notifications
    assert "$PARENT_DIR/scripts/notify.sh 'Test notification' INFO" \
          "Système de notification"
    
    # Test rapports
    assert "$PARENT_DIR/scripts/report.sh ${SCENARIOS_DIR}/test_light.sh" \
          "Génération de rapports"
}

# 5. Tests de Performances
test_performance() {
    echo "=== Test des performances ==="
    
    # Test charge parallèle
    start_time=$(date +%s)
    
    $PARENT_DIR/orchestrator.sh -t "${SCENARIOS_DIR}/test_light.sh" &
    $PARENT_DIR/orchestrator.sh -t "${SCENARIOS_DIR}/test_light.sh" &
    $PARENT_DIR/orchestrator.sh -t "${SCENARIOS_DIR}/test_light.sh" &
    
    wait
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    assert "[ $duration -lt 30 ]" \
          "Performance en parallèle (durée: ${duration}s)"
}

# 6. Tests d'Erreurs
test_error_handling() {
    echo "=== Test de la gestion des erreurs ==="
    
    # Test script inexistant
    assert "! $PARENT_DIR/orchestrator.sh -f nonexistent.sh 2>&1 | grep -q 'SUCCESS'" \
          "Gestion script inexistant"
    
    # Test option invalide
    assert "! $PARENT_DIR/orchestrator.sh -z 2>&1 | grep -q 'SUCCESS'" \
          "Gestion option invalide"
    
    # Test paramètres manquants
    assert "! $PARENT_DIR/orchestrator.sh -l 2>&1 | grep -q 'SUCCESS'" \
          "Gestion paramètres manquants"
}

# Exécution de tous les tests
main() {
    echo "=== Début des tests détaillés ==="
    echo "Date: $(date)"
    echo "---"
    
    mkdir -p "$(dirname "$LOG_FILE")"
    
    test_required_options
    test_scenarios
    test_security
    test_added_features
    test_performance
    test_error_handling
    
    echo "=== Fin des tests détaillés ==="
    echo "Consultez ${LOG_FILE} pour les résultats détaillés"
}

# Lancer les tests
main
