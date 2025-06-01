#!/bin/bash
# Script de test simple pour BashOrchestrator

echo "Début du script de test backup.sh"
echo "PID: $$"
sleep 2
echo "Fin du script de test backup.sh"

# Création du répertoire de sauvegarde s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Création de l'archive
tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "Sauvegarde créée avec succès: $BACKUP_FILE"
    exit 0
else
    echo "Erreur lors de la création de la sauvegarde"
    exit 1
fi
