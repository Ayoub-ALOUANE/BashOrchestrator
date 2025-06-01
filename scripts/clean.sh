#!/bin/bash
# Script de test simple pour BashOrchestrator

echo "Début du script de test clean.sh"
echo "PID: $$"
sleep 1
echo "Fin du script de test clean.sh"

# Fonction pour nettoyer un répertoire
clean_directory() {
    local dir=$1
    local age=$2
    
    if [ ! -d "$dir" ]; then
        echo "Le répertoire $dir n'existe pas"
        return 1
    }
    
    find "$dir" -type f -mtime +$age -delete 2>/dev/null
    find "$dir" -type d -empty -delete 2>/dev/null
    
    echo "Nettoyage terminé pour $dir"
}

# Nettoyage des répertoires temporaires
for dir in "${TEMP_DIRS[@]}"; do
    echo "Nettoyage de $dir..."
    clean_directory "$dir" "$MAX_AGE_DAYS"
done

# Nettoyage des logs
for dir in "${LOG_DIRS[@]}"; do
    echo "Nettoyage des logs dans $dir..."
    clean_directory "$dir" "$MAX_AGE_DAYS"
done

exit 0
