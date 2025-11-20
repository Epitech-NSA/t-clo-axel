# Runbooks opérationnels

Ce dossier contient les procédures opérationnelles (runbooks) pour déployer et gérer l'infrastructure TERRACLOUD.

## Qu'est-ce qu'un runbook ?

Un runbook est un document procédural qui décrit les étapes exactes à suivre pour accomplir une tâche opérationnelle. Chaque runbook suit un format standardisé :

- **Objectif** : Ce que le runbook accomplit
- **Prérequis** : Ce dont vous avez besoin avant de commencer
- **Procédure** : Étapes numérotées avec des checkpoints
- **Vérification** : Comment valider que tout fonctionne
- **Checklist** : Liste de contrôle finale

## Runbooks disponibles

### [Runbook PaaS](runbook-paas.md)

Déploiement de l'application sur Azure App Service (Platform as a Service).

**Utiliser quand:**
- Déploiement simple et rapide souhaité
- Maintenance automatique préférée
- Contrôle infrastructure limité acceptable

**Durée:** ~15-20 minutes

**Commande rapide:**
```bash
make dev-paas
```

---

### [Runbook IaaS](runbook-iaas.md)

Déploiement de l'application sur VM Scale Set avec Ansible (Infrastructure as a Service).

**Utiliser quand:**
- Contrôle total de l'infrastructure requis
- Configuration personnalisée nécessaire
- Auto-scaling avec contrôle fin souhaité

**Durée:** ~30-35 minutes

**Commande rapide:**
```bash
make dev-iaas
```

---

### [Runbook Destruction](runbook-destroy.md)

Suppression propre des ressources Azure pour éviter les coûts.

**Utiliser quand:**
- Environnement de développement à nettoyer
- Ressources temporaires à supprimer
- Changement d'architecture complet

**⚠️ ATTENTION:** Procédure irréversible

**Commande rapide:**
```bash
make destroy-dev COMPONENT=all
```

## Guide de navigation

### Vous souhaitez...

| Objectif | Runbook | Temps |
|----------|---------|-------|
| Déployer rapidement une app | [PaaS](runbook-paas.md) | 15 min |
| Avoir le contrôle total | [IaaS](runbook-iaas.md) | 30 min |
| Supprimer l'infrastructure | [Destroy](runbook-destroy.md) | 10 min |
| Mettre à jour l'application | [PaaS](runbook-paas.md#mise-à-jour-de-lapplication) ou [IaaS](runbook-iaas.md#mise-à-jour-de-lapplication) | 5 min |
| Scaler l'application | [PaaS](runbook-paas.md#scaling) ou [IaaS](runbook-iaas.md#scaling) | 2 min |

### Vous rencontrez un problème...

**Ne cherchez pas dans les runbooks !** Consultez plutôt :
- [Troubleshooting PaaS](../troubleshooting/paas-troubleshooting.md)
- [Troubleshooting IaaS](../troubleshooting/iaas-troubleshooting.md)
- [Problèmes communs](../troubleshooting/common-issues.md)

## Workflows types

### Workflow 1: Premier déploiement (PaaS)

```bash
# 1. Lire le runbook
cat docs/runbooks/runbook-paas.md

# 2. Vérifier les prérequis
az --version
terraform --version

# 3. Déployer
make dev-paas

# 4. Vérifier
make test-paas ENV=dev
```

### Workflow 2: Premier déploiement (IaaS)

```bash
# 1. Lire le runbook
cat docs/runbooks/runbook-iaas.md

# 2. Vérifier les prérequis
ansible --version

# 3. Générer les clés SSH
ssh-keygen -t ed25519 -f ~/.ssh/terracloud-dev-key

# 4. Déployer
make dev-iaas

# 5. Vérifier
make test-iaas ENV=dev
```

### Workflow 3: Mise à jour d'application

```bash
# 1. Modifier le code
nano sample-app-master/...

# 2. Rebuild et push
make build-push ENV=dev

# 3. Redéployer
make dev-paas  # ou make dev-iaas

# 4. Vérifier
curl https://tc-dev-web-frc-01.azurewebsites.net
```

### Workflow 4: Nettoyage complet

```bash
# 1. Lire le runbook destruction
cat docs/runbooks/runbook-destroy.md

# 2. Sauvegarder si nécessaire
# (voir runbook)

# 3. Détruire
make destroy-dev COMPONENT=all

# 4. Vérifier
az resource list --resource-group rg-nan_1
```

## Conventions des runbooks

### Format des commandes

Toutes les commandes sont prêtes à copier-coller. Les variables sont clairement indiquées :

```bash
# Mauvais exemple (ne pas utiliser)
az webapp restart --name <webapp-name>

# Bon exemple (utilisé dans nos runbooks)
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

### Checkpoints

Chaque étape majeure a un **Checkpoint** pour valider la progression :

```bash
# Commandes...

**Checkpoint**: Description de ce qui doit être validé
```

### Durées estimées

Les durées sont indicatives et basées sur :
- Connexion internet standard (100 Mbps)
- Région Azure France Central
- Heures de faible charge (hors 10h-16h)

Ajoutez 20-30% en heures de pointe.

## Ressources complémentaires

### Documentation associée

- **Guides**: [Guide de démarrage](../guides/getting-started.md)
- **Architecture**: [Vue d'ensemble](../reference/architecture/overview.md)
- **Opérations**: [Opérations quotidiennes](../operations/daily-operations.md)
- **Troubleshooting**: [Index des problèmes](../troubleshooting/README.md)

### Outils

- **Makefile**: Commandes simplifiées (`make help`)
- **Scripts**: [Référence des scripts](../operations/scripts-reference.md)
- **CI/CD**: [Automatisation](../operations/cicd-reference.md)

## Support

### En cas de problème

1. **Consulter le troubleshooting** correspondant à votre déploiement
2. **Vérifier les logs** : `make logs-paas ENV=dev` ou `make logs-iaas ENV=dev`
3. **Consulter la documentation** Azure officielle
4. **Ouvrir une issue** sur le projet

### Contribution

Pour améliorer un runbook :

1. Tester la procédure complète
2. Noter les points bloquants
3. Proposer des améliorations claires
4. Mettre à jour la documentation

## Notes importantes

- **Les runbooks ne contiennent PAS de troubleshooting** : Consultez le dossier `troubleshooting/`
- **Les runbooks sont procéduraux** : Suivez les étapes dans l'ordre
- **Les checkpoints sont obligatoires** : Validez chaque étape
- **Les commandes sont complètes** : Pas de placeholders génériques

---

**Dernière mise à jour** : 2024
**Projet** : TERRACLOUD - Epitech T-CLO-900

