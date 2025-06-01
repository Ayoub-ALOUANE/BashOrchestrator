#!/bin/bash
# Scénario de test lourd
echo "Démarrage du test lourd"
echo "PID: $$"

# Simulation d'une charge lourde
echo "Traitement intensif en cours..."
for i in {1..15}; do
    echo "Phase $i/15..."
    # Simuler une charge CPU plus importante
    for j in {1..5000}; do
        echo "test" > /dev/null
    done
    # Simuler utilisation mémoire
    array=()
    for k in {1..1000}; do
        array+=("data$k")
    done
    sleep 3
done

echo "Test lourd terminé"
exit 0
