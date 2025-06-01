#!/bin/bash
# Gestionnaire de restauration pour BashOrchestrator

# Fonction pour sauvegarder la configuration actuelle
backup_config() {
    local config="$1"
    if [ -f "$config" ]; then
        cp "$config" "${config}.bak"
        return $?
    fi
    return 1
}

# Fonction pour restaurer la configuration par défaut
restore_defaults() {
    local config="$1"
    local script_dir="$2"
    
    # Sauvegarder d'abord
    backup_config "$config"
    
    # Configuration par défaut
    cat > "$config" << EOF
{
  "scripts": [
    {
      "name": "test_modes.sh",
      "description": "Script de test des trois scénarios",
      "status": "enabled",
      "timeout": 3600
    }
  ],
  "features": {
    "notifications": true,
    "dependencies": true,
    "monitoring": true
  },
  "settings": {
    "max_concurrent_scripts": 3,
    "log_retention_days": 30,
    "notification_email": "",
    "enable_email_notifications": false
  }
}
EOF

    return $?
}

# Fonction pour restaurer depuis la sauvegarde
rollback_restore() {
    local config="$1"
    if [ -f "${config}.bak" ]; then
        mv "${config}.bak" "$config"
        return $?
    fi
    return 1
}
