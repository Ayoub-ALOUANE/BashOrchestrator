#!/bin/bash
# Test combiné : charge moyenne + notifications

# Source des scripts nécessaires
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/notify.sh"

echo "Démarrage du test combiné"
send_notification "Démarrage du test combiné" "INFO"

# Exécution du test moyen avec notifications
"${SCRIPT_DIR}/test_medium.sh" &
TEST_PID=$!

# Monitoring avec notifications
while kill -0 $TEST_PID 2>/dev/null; do
    CPU_USAGE=$(ps -p $TEST_PID -o %cpu | tail -n 1)
    MEM_USAGE=$(ps -p $TEST_PID -o %mem | tail -n 1)
    
    if (( $(echo "$CPU_USAGE > 50" | bc -l) )); then
        send_notification "Haute utilisation CPU: ${CPU_USAGE}%" "WARNING"
    fi
    
    if (( $(echo "$MEM_USAGE > 50" | bc -l) )); then
        send_notification "Haute utilisation mémoire: ${MEM_USAGE}%" "WARNING"
    fi
    
    sleep 5
done

wait $TEST_PID
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    send_notification "Test combiné terminé avec succès" "SUCCESS"
else
    send_notification "Test combiné échoué avec code $EXIT_CODE" "ERROR"
fi

exit $EXIT_CODE
