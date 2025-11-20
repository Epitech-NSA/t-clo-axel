# Operations - Documentation opérationnelle

Ce dossier contient la documentation de référence pour les opérations quotidiennes et la gestion de l'infrastructure TERRACLOUD.

## Contenu

### [Scripts Reference](scripts-reference.md)

Documentation complète de tous les scripts bash et du Makefile.

**Utiliser pour:**
- Comprendre les scripts disponibles
- Référence des commandes Makefile
- Workflows types d'utilisation

---

### [CI/CD Reference](cicd-reference.md)

Documentation des workflows GitHub Actions.

**Utiliser pour:**
- Configurer les pipelines CI/CD
- Comprendre les workflows automatisés
- Gérer les secrets GitHub
- Stratégie de déploiement

---

### [Daily Operations](daily-operations.md)

Guide des opérations courantes au quotidien.

**Utiliser pour:**
- Monitoring et logs
- Accès SSH
- Mise à jour d'applications
- Health checks
- Gestion des coûts

---

### [Advanced Configuration](advanced-configuration.md)

Configurations avancées et optimisations.

**Utiliser pour:**
- Auto-scaling avancé
- Domaines personnalisés et SSL
- Backup automatique
- Monitoring avancé
- Optimisation des coûts

## Guide rapide

### Vous voulez...

| Objectif | Document | Section |
|----------|----------|---------|
| Voir les logs | [Daily Operations](daily-operations.md#monitoring) | Monitoring |
| SSH vers une VM | [Daily Operations](daily-operations.md#accès-ssh) | Accès SSH |
| Mettre à jour l'app | [Daily Operations](daily-operations.md#mise-à-jour-de-lapplication) | Mise à jour |
| Gérer les coûts | [Daily Operations](daily-operations.md#gestion-des-coûts) | Coûts |
| Utiliser le Makefile | [Scripts Reference](scripts-reference.md#makefile) | Makefile |
| Configurer GitHub Actions | [CI/CD Reference](cicd-reference.md#configuration-des-secrets) | CI/CD |
| Configurer auto-scaling | [Advanced Configuration](advanced-configuration.md#auto-scaling-avancé) | Advanced |
| Ajouter un domaine | [Advanced Configuration](advanced-configuration.md#domaine-personnalisé-et-ssl) | Advanced |

## Navigation

### Par type d'opération

#### Opérations quotidiennes
→ [Daily Operations](daily-operations.md)

#### Référence des outils
→ [Scripts Reference](scripts-reference.md)
→ [CI/CD Reference](cicd-reference.md)

#### Configurations avancées
→ [Advanced Configuration](advanced-configuration.md)

### Par problème

**Si vous rencontrez un problème**, consultez plutôt:
- [Troubleshooting](../troubleshooting/README.md)

### Par procédure

**Pour suivre une procédure complète**, consultez plutôt:
- [Runbooks](../runbooks/README.md)

## Différence entre Operations et Runbooks

| Aspect | Operations | Runbooks |
|--------|-----------|----------|
| **Type** | Documentation de référence | Procédures pas-à-pas |
| **Usage** | Consulter pour comprendre | Suivre pour exécuter |
| **Format** | Référence, exemples | Étapes numérotées |
| **Objectif** | Comprendre les outils | Accomplir une tâche |

**Exemple**:
- **Runbook** : "Déployer PaaS en suivant ces 10 étapes"
- **Operations** : "Référence de toutes les commandes Make disponibles"

## Parcours recommandés

### Nouveau sur le projet

1. [Guide de démarrage](../guides/getting-started.md)
2. [Runbook PaaS](../runbooks/runbook-paas.md)
3. [Daily Operations](daily-operations.md)

### DevOps

1. [CI/CD Reference](cicd-reference.md)
2. [Scripts Reference](scripts-reference.md)
3. [Advanced Configuration](advanced-configuration.md)

### Support/Maintenance

1. [Daily Operations](daily-operations.md)
2. [Troubleshooting](../troubleshooting/README.md)
3. [Advanced Configuration](advanced-configuration.md)

## Liens utiles

### Documentation du projet

- [README principal](../../README.md)
- [Index documentation](../README.md)
- [Runbooks](../runbooks/README.md)
- [Troubleshooting](../troubleshooting/README.md)
- [Guides](../guides/README.md)
- [Référence](../reference/README.md)

### Documentation externe

- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)

## Support

Pour toute question opérationnelle:
1. Consulter ce dossier operations
2. Consulter le [troubleshooting](../troubleshooting/README.md)
3. Vérifier les logs de l'application
4. Ouvrir une issue

---

**Dernière mise à jour**: 2024
**Projet**: TERRACLOUD - Epitech T-CLO-900

