# BashOrchestrator

Un gestionnaire intelligent de scripts Bash offrant trois modes d'exécution puissants pour répondre aux besoins d'administration système.

## Objectif
Fournir un outil robuste et simple pour l'exécution de scripts système avec trois modes d'exécution distincts, permettant une gestion efficace des processus selon les besoins spécifiques.

## Valeur Ajoutée
- **Flexibilité d'Exécution**
  - Mode Fork : Idéal pour les tâches nécessitant une isolation complète
  - Mode Thread : Optimal pour les opérations parallèles
  - Mode Sous-shell : Parfait pour l'exécution dans un environnement contrôlé

- **Sécurité et Contrôle**
  - Gestion stricte des privilèges administrateur
  - Protection des ressources système sensibles
  - Validation de sécurité intégrée

- **Traçabilité**
  - Journalisation système complète
  - Historique des exécutions
  - Codes d'erreur normalisés

## Structure Technique
```
orchestrator.sh           # Script principal avec les 6 options obligatoires
├── scripts/
│   ├── admin_check.sh    # Gestion des privilèges administrateur
│   ├── process_manager.sh # Gestion des modes d'exécution
│   └── test_modes.sh     # Scénarios de test (léger/moyen/lourd)
│
├── src/
│   └── security/
│       └── validation.sh # Validation de sécurité
│
├── config/
│   └── config.json      # Configuration de base
│
└── logs/
    └── orchestrator.log # Journalisation
```

## Fonctionnalités Essentielles

1. **Options de Base** :
   - `-h` : Aide et documentation
   - `-f` : Exécution en mode fork (processus isolé)
   - `-t` : Exécution en mode thread (parallèle)
   - `-s` : Exécution en sous-shell (environnement isolé)
   - `-l` : Configuration des logs (admin)
   - `-r` : Réinitialisation (admin)

2. **Modes d'Exécution Spécialisés** :
   - **Fork** : Pour les tâches nécessitant une isolation
   - **Thread** : Pour les opérations parallèles
   - **Sous-shell** : Pour un environnement contrôlé

3. **Scénarios de Test** :
   - Test Léger : Validation rapide
   - Test Moyen : Test standard
   - Test Lourd : Test de charge

4. **Journalisation** :
   - Journal système : /var/log/bashorchestrator/history.log
   - Journal local : logs/orchestrator.log

5. **Sécurité** :
   - Contrôle d'accès administrateur
   - Validation des entrées
   - Codes d'erreur standardisés