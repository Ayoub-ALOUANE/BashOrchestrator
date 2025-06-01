#!/bin/bash
# Script simple de notification (fonctionnalité additionnelle)

# Envoyer une notification simple
send_notification() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Notification locale
    echo "[$timestamp] $level: $message"
    
    # Notification système si disponible
    if command -v notify-send &> /dev/null; then
        notify-send "BashOrchestrator" "$level: $message"
    fi
    
    # Log la notification
    echo "[$timestamp] $level: $message" >> "logs/orchestrator.log"
}

# Usage direct du script
if [ "$#" -gt 0 ]; then
    send_notification "$@"
fi
