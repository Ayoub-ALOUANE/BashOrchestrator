#!/bin/bash
# Scénario de test moyen
echo "Démarrage du test moyen"
echo "PID: $$"

# Simulation d'une charge moyenne
echo "Calcul en cours..."
for i in {1..10}; do
    echo "Progression: $((i*10))%"
    # Simuler un peu de charge CPU
    for j in {1..1000}; do
        echo "test" > /dev/null
    done
    sleep 2
done

echo "Test moyen terminé"
exit 0
