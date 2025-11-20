# Documentation TERRACLOUD

Bienvenue dans la documentation complète du projet TERRACLOUD - Infrastructure as Code sur Microsoft Azure.

## Structure de la documentation

```
docs/
├── guides/              # Guides pratiques pour démarrer
├── runbooks/            # Procédures opérationnelles de déploiement
├── troubleshooting/     # Guides de dépannage
├── operations/          # Documentation opérationnelle de référence
└── reference/           # Documentation technique de référence
```

## Navigation rapide

| Vous êtes... | Commencez par... |
|--------------|------------------|
| **Nouveau sur le projet** | [Guide de démarrage rapide](guides/getting-started.md) |
| **Utilisateur de l'application** | [Guide utilisateur](guides/user-guide.md) |
| **Prêt à déployer PaaS** | [Runbook PaaS](runbooks/runbook-paas.md) |
| **Prêt à déployer IaaS** | [Runbook IaaS](runbooks/runbook-iaas.md) |
| **Rencontrez un problème** | [Troubleshooting](troubleshooting/README.md) |
| **Opérations quotidiennes** | [Daily Operations](operations/daily-operations.md) |
| **Comprendre l'architecture** | [Architecture Overview](reference/architecture/overview.md) |

## Guides pratiques

### [Guides](guides/README.md)

Guides d'introduction et d'utilisation.

- **[Guide de démarrage rapide](guides/getting-started.md)** - Installation et premier déploiement (30min)
- **[Guide utilisateur](guides/user-guide.md)** - Utilisation de l'application déployée

## Runbooks opérationnels

### [Runbooks](runbooks/README.md)

Procédures opérationnelles pas-à-pas.

- **[Runbook PaaS](runbooks/runbook-paas.md)** - Déploiement Azure App Service (15-20min)
- **[Runbook IaaS](runbooks/runbook-iaas.md)** - Déploiement VM Scale Set (30-35min)
- **[Runbook Destruction](runbooks/runbook-destroy.md)** - Suppression des ressources

## Troubleshooting

### [Troubleshooting](troubleshooting/README.md)

Guides de dépannage par type de problème.

- **[PaaS Troubleshooting](troubleshooting/paas-troubleshooting.md)** - Problèmes Azure App Service
- **[IaaS Troubleshooting](troubleshooting/iaas-troubleshooting.md)** - Problèmes VM Scale Set
- **[CI/CD Troubleshooting](troubleshooting/cicd-troubleshooting.md)** - Problèmes GitHub Actions
- **[Scripts Troubleshooting](troubleshooting/scripts-troubleshooting.md)** - Problèmes scripts bash
- **[Common Issues](troubleshooting/common-issues.md)** - Problèmes Azure/Terraform/Docker

## Operations

### [Operations](operations/README.md)

Documentation opérationnelle de référence.

- **[Scripts Reference](operations/scripts-reference.md)** - Documentation des scripts et Makefile
- **[CI/CD Reference](operations/cicd-reference.md)** - Documentation GitHub Actions
- **[Daily Operations](operations/daily-operations.md)** - Opérations quotidiennes (logs, monitoring, etc.)
- **[Advanced Configuration](operations/advanced-configuration.md)** - Configurations avancées

## Reference

### [Reference](reference/README.md)

Documentation technique de référence.

#### Architecture
- **[Vue d'ensemble](reference/architecture/overview.md)** - Architecture générale
- **[Infrastructure partagée](reference/architecture/infrastructure-shared.md)** - Ressources communes
- **[Architecture PaaS](reference/architecture/architecture-paas.md)** - Détails PaaS
- **[Architecture IaaS](reference/architecture/architecture-iaas.md)** - Détails IaaS

#### Autres
- **[Comparaison PaaS vs IaaS](reference/comparison.md)** - Analyse détaillée
- **[Conventions de nommage](reference/conventions.md)** - Standards Azure

## Organisation de la documentation

| Type | Dossier | Utilisation |
|------|---------|-------------|
| **Guides** | `guides/` | Apprendre et démarrer |
| **Runbooks** | `runbooks/` | Procédures de déploiement |
| **Troubleshooting** | `troubleshooting/` | Résoudre les problèmes |
| **Operations** | `operations/` | Référence opérationnelle |
| **Reference** | `reference/` | Documentation technique |


## Technologies documentées

| Technologie | Documentation |
|-------------|---------------|
| **Azure CLI** | [Scripts Reference](operations/scripts-reference.md), [Troubleshooting](troubleshooting/common-issues.md) |
| **Terraform** | [Runbooks](runbooks/README.md), [Troubleshooting](troubleshooting/common-issues.md) |
| **Ansible** | [Runbook IaaS](runbooks/runbook-iaas.md), [IaaS Troubleshooting](troubleshooting/iaas-troubleshooting.md) |
| **Docker** | [Scripts Reference](operations/scripts-reference.md), [Troubleshooting](troubleshooting/common-issues.md) |
| **GitHub Actions** | [CI/CD Reference](operations/cicd-reference.md), [CI/CD Troubleshooting](troubleshooting/cicd-troubleshooting.md) |

## Glossaire

### Acronymes Azure

- **ACR**: Azure Container Registry
- **ASP**: App Service Plan
- **NSG**: Network Security Group
- **PIP**: Public IP
- **RG**: Resource Group
- **VMSS**: Virtual Machine Scale Set
- **VNet**: Virtual Network

### Concepts

- **PaaS**: Platform as a Service - Services cloud managés
- **IaaS**: Infrastructure as a Service - Serveurs virtuels
- **IaC**: Infrastructure as Code - Infrastructure définie en code
- **Runbook**: Procédure opérationnelle documentée

## Conventions documentaires

### Format des documents

Tous les documents suivent une structure cohérente:

1. **Introduction** - Contexte et objectifs
2. **Prérequis** - Ce dont vous avez besoin
3. **Instructions** - Procédures ou explications détaillées
4. **Exemples** - Code et commandes
5. **Références** - Liens vers autres documents

### Codes et commandes

- Toutes les commandes sont prêtes à copier-coller
- Pas de placeholders génériques (ex: `<nom>`)
- Valeurs réelles pour le projet

### Navigation

- Liens relatifs entre documents
- README.md dans chaque dossier pour la navigation
- Liens bidirectionnels (aller-retour)

## Support et ressources

### Documentation officielle

- [Microsoft Azure Documentation](https://learn.microsoft.com/fr-fr/azure/)
- [Terraform Registry](https://registry.terraform.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Laravel Documentation](https://laravel.com/docs)

### Projet TERRACLOUD

- [README principal](../README.md) - Vue d'ensemble du projet
- [Code source](../) - Repository complet
- Epitech T-CLO-900

---

**Navigation rapide:**
- [Retour au README principal](../README.md)
- [Guide de démarrage rapide](guides/getting-started.md)
- [Runbooks](runbooks/README.md)
- [Troubleshooting](troubleshooting/README.md)

**Projet éducatif - Epitech 2025**
