#!/bin/bash

# Script de test pour les trois scénarios requis
# Usage: ./test_modes.sh [light|medium|heavy]

# Configuration des scénarios de test conformes au cahier des charges
ITERATIONS_LIGHT=1000    # Test léger
ITERATIONS_MEDIUM=5000   # Test moyen
ITERATIONS_HEAVY=10000   # Test lourd

# Fonction pour simuler une charge de travail
simulate_load() {
    local iterations=$1
    local sum=0
    local start_time=$(date +%s)
    
    echo "Démarrage du test avec $iterations itérations..."
    echo "PID: $$"
    echo "Mode d'exécution: $2"
    
    for ((i=1; i<=iterations; i++)); do
        sum=$((sum + i))
        if ((i % 1000 == 0)); then
            echo "Progression: $i/$iterations"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Test terminé en $duration secondes"
    echo "Résultat final: $sum"
}

# Sélection du mode de test
case "${1:-light}" in
    "light")
        echo "=== Test léger (calculs simples) ==="
        simulate_load $ITERATIONS_LIGHT "$2"
        ;;
    "medium")
        echo "=== Test moyen (calculs intermédiaires) ==="
        simulate_load $ITERATIONS_MEDIUM "$2"
        ;;
    "heavy")
        echo "=== Test lourd (calculs intensifs) ==="
        simulate_load $ITERATIONS_HEAVY "$2"
        ;;
    *)
        echo "Mode non reconnu. Utilisation du mode light."
        simulate_load $ITERATIONS_LIGHT "$2"
        ;;
esac

exit 0
