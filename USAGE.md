# Guide d'Utilisation BashOrchestrator

## Options Obligatoires

1. `-h` : Affiche l'aide
   ```bash
   ./orchestrator.sh -h
   ```

2. `-f` : Exécute en mode fork (processus séparé)
   ```bash
   ./orchestrator.sh -f test_modes.sh [light|medium|heavy]
   ```

3. `-t` : Exécute en mode thread (parallèle)
   ```bash
   ./orchestrator.sh -t test_modes.sh [light|medium|heavy]
   ```

4. `-s` : Exécute en mode sous-shell
   ```bash
   ./orchestrator.sh -s test_modes.sh [light|medium|heavy]
   ```

5. `-l` : Configure les logs (requiert admin)
   ```bash
   sudo ./orchestrator.sh -l /var/log/bashorchestrator
   ```

6. `-r` : Réinitialise la configuration (requiert admin)
   ```bash
   sudo ./orchestrator.sh -r
   ```

## Scénarios de Test

Les trois scénarios de test permettent d'évaluer les différents modes d'exécution :

1. Test Léger
   ```bash
   ./orchestrator.sh -f test_modes.sh light
   ```

2. Test Moyen
   ```bash
   ./orchestrator.sh -t test_modes.sh medium
   ```

3. Test Lourd
   ```bash
   ./orchestrator.sh -s test_modes.sh heavy
   ```
## Journal système

Les logs sont stockés à deux emplacements :
1. Journal système (requiert admin) :
   ```
   /var/log/bashorchestrator/history.log
   ```

2. Journal local :
   ```
   logs/orchestrator.log
   ```

## Codes d'Erreur
Les codes suivants sont utilisés pour indiquer l'état de l'exécution :

- 100 : Option invalide
- 101 : Paramètre manquant
- 102 : Privilèges administrateur requis
- 103 : Échec de l'exécution
- 104 : Configuration invalide

## Privilèges Administrateur

Deux options nécessitent des privilèges administrateur :
- `-l` : Pour configurer le répertoire des logs système
- `-r` : Pour réinitialiser la configuration

## Fonctionnalités Additionnelles

### Planification Simple
Pour exécuter un script après un délai :
```bash
./orchestrator.sh --schedule script.sh 30  # Exécute dans 30 minutes
```

### Surveillance Basique
Pour surveiller un script en cours d'exécution :
```bash
./orchestrator.sh --monitor status PID
./orchestrator.sh --monitor stats PID
```

### Rapports Simples
Pour générer un rapport d'exécution :
```bash
./orchestrator.sh --report script.sh
```

### Exécution avec Dépendances
Pour exécuter un script qui dépend d'un autre :
```bash
./orchestrator.sh -f script2.sh --depends-on script1.sh
```

### Notifications
Pour activer les notifications :
```bash
./orchestrator.sh --notify "Message" "INFO"
```

### Exemples d'Utilisation Avancée

1. Exécution avec dépendance et notification :
```bash
./orchestrator.sh -f backup.sh --depends-on check.sh --notify
```

2. Test avec notification des résultats :
```bash
./orchestrator.sh -t test_modes.sh heavy --notify
```

Note: Ces fonctionnalités additionnelles sont optionnelles et ne font pas partie des exigences du cahier des charges.
