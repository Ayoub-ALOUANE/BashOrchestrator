#!/bin/bash
# Génération de rapports simples (fonctionnalité additionnelle)

# Générer un rapport d'exécution basique
generate_report() {
    local script="$1"
    local output_file="logs/report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Rapport d'Exécution ==="
        echo "Date: $(date)"
        echo "Script: $script"
        echo "---"
        
        # Récupérer les dernières lignes de log
        echo "Dernières entrées de log:"
        tail -n 10 "logs/orchestrator.log"
        
        # État du script
        echo "---"
        echo "État actuel:"
        ps aux | grep "$script" | grep -v grep
        
    } > "$output_file"
    
    echo "Rapport généré: $output_file"
}

# Usage direct
if [ "$#" -gt 0 ]; then
    generate_report "$1"
fi
