#!/bin/bash
# Scénario de test léger
echo "Démarrage du test léger"
echo "PID: $$"

# Simulation d'une charge légère
for i in {1..5}; do
    echo "Étape $i/5..."
    sleep 1
done

echo "Test léger terminé"
exit 0
