# TERRACLOUD

[![Terraform](https://img.shields.io/badge/Terraform-1.13+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![Ansible](https://img.shields.io/badge/Ansible-2.16+-EE0000?logo=ansible)](https://www.ansible.com/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED?logo=docker)](https://www.docker.com/)
[![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub_Actions-2088FF?logo=github-actions)](https://github.com/features/actions)

**Infrastructure as Code (IaC) production-ready sur Microsoft Azure**

Plateforme complète de déploiement cloud comparant PaaS et IaaS, avec CI/CD automatisé, monitoring, et HTTPS.

## 🎯 Vue d'ensemble

TERRACLOUD est un projet d'infrastructure production-ready démontrant les pratiques de déploiement cloud sur Microsoft Azure. Le projet propose deux architectures complètes (PaaS et IaaS) avec automatisation CI/CD, scripts de déploiement, tests automatisés, et documentation exhaustive.

### ✨ Fonctionnalités principales

- **Déploiement automatisé** : Scripts bash et Makefile pour déploiement en un clic
- **CI/CD complet** : GitHub Actions pour build/test/deploy automatiques
- **HTTPS/SSL** : Configuration automatique avec Let's Encrypt
- **Tests automatisés** : Suite de tests pour PaaS, IaaS, HTTPS, et Database
- **Monitoring** : Health checks et logs centralisés
- **Production-ready** : Checklist complète et procédures de rollback
- **Documentation exhaustive** : Guides détaillés pour chaque composant

### 🏗️ Les deux approches

**PaaS (Platform as a Service)**
- Azure App Service pour l'hébergement
- Déploiement simplifié en 15 minutes
- Maintenance managée par Azure
- HTTPS natif avec certificat managé

**IaaS (Infrastructure as a Service)**
- VM Scale Set
- Contrôle total de l'infrastructure
- Configuration via Ansible
- HTTPS avec Let's Encrypt et Nginx

### 🛠️ Stack technique complète

- **Application**: Laravel (PHP) avec MySQL
- **Conteneurisation**: Docker + ACR
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **CI/CD**: GitHub Actions
- **Reverse Proxy**: Nginx (IaaS)
- **SSL/TLS**: Let's Encrypt
- **Cloud Provider**: Microsoft Azure

## Objectifs pédagogiques

1. Comparer les approches PaaS et IaaS en situation réelle
2. Maîtriser Terraform pour l'infrastructure as code
3. Automatiser les déploiements avec Ansible
4. Implémenter les bonnes pratiques Azure
5. Gérer la scalabilité et la haute disponibilité

---

## 📁 Structure du projet

```
T-CLO-900/
├── terraform/          # Infrastructure as Code (modules, configs)
├── ansible/            # Automatisation IaaS (playbooks, roles)
├── scripts/            # Scripts bash d'automatisation
├── tests/              # Tests automatisés
├── docs/               # Documentation complète
├── sample-app-master/  # Application Laravel
├── .github/workflows/  # CI/CD GitHub Actions
└── Makefile           # Commandes simplifiées
```

**Concepts clés** : Terraform Workspaces (multi-env), Ansible (IaaS automation), GitHub Actions (CI/CD), Docker + ACR

---

## 🚀 Démarrage rapide

```bash
# 1. Cloner et configurer
git clone https://github.com/Epitech-NSA/t-clo-axel && cd t-clo-axel
make setup

# 2. Déployer (PaaS ou IaaS)
make build-push ENV=dev
make dev-paas              # PaaS: 15 minutes
# OU
make dev-iaas              # IaaS: 30 minutes

# 3. Tester
make test-paas ENV=dev
make urls ENV=dev
```

**Prérequis** : Azure CLI, Terraform, Docker, Git (+ Ansible pour IaaS)

➡️ **Guide complet** : [docs/guides/getting-started.md](docs/guides/getting-started.md)  
➡️ **Procédures détaillées** : [Runbook PaaS](docs/runbooks/runbook-paas.md) | [Runbook IaaS](docs/runbooks/runbook-iaas.md)

---

## 🤖 CI/CD Automatisé

GitHub Actions intégré pour automatisation complète :
- **Build automatique** sur push (main/develop)
- **Validation Terraform** sur Pull Request
- **Déploiement manuel** PaaS/IaaS (dev/prod)
- **Scans de sécurité** (Trivy, tfsec)

➡️ **Documentation complète** : [docs/operations/cicd-reference.md](docs/operations/cicd-reference.md)

---

## Approche PaaS (App Service)

**Azure App Service** pour un déploiement simplifié et managé.

✅ **Avantages** : Déploiement rapide (15min), maintenance automatique, coût ~32€/mois  
❌ **Inconvénients** : Contrôle limité, dépendance plateforme

➡️ **Runbook complet** : [docs/runbooks/runbook-paas.md](docs/runbooks/runbook-paas.md)

---

## Approche IaaS (VM Scale Set)

**VM Scale Set + Ansible** pour un contrôle total de l'infrastructure.

✅ **Avantages** : Contrôle complet, flexibilité maximale, configuration personnalisée  
❌ **Inconvénients** : Déploiement plus long (30min), maintenance manuelle, coût ~53€/mois

➡️ **Runbook complet** : [docs/runbooks/runbook-iaas.md](docs/runbooks/runbook-iaas.md)

---

## Architecture

Deux architectures parallèles partageant la même infrastructure de base (VNet, ACR, MySQL).

**PaaS** : `Internet → App Service → ACR → MySQL`  
**IaaS** : `Internet → VM Scale Set (Public IPs) → Docker → ACR → MySQL`

➡️ **Documentation architecturale** : [docs/reference/architecture/overview.md](docs/reference/architecture/overview.md)

---

## Comparaison PaaS vs IaaS

| Critère | PaaS (App Service) | IaaS (VMSS) |
|---------|-------------------|-------------|
| **Temps de déploiement** | 15 minutes | 30-35 minutes |
| **Complexité** | Faible | Élevée |
| **Contrôle infrastructure** | Limité | Total |
| **Maintenance** | Automatique | Manuelle |
| **Coût mensuel (dev)** | ~32€ | ~53€ |
| **Scalabilité** | Automatique | Configurable |
| **Cas d'usage idéal** | Applications standard | Besoins spécifiques |

➡️ **Analyse détaillée** : [docs/reference/comparison.md](docs/reference/comparison.md)

---

## Configuration

**Environnements** : `dev` (France Central) | `prod` (France Central)  
**Variables Terraform** : `terraform.tfvars` (mysql_admin_password, ssh_public_key_iaas pour IaaS)

➡️ **Configuration détaillée** : [docs/guides/getting-started.md](docs/guides/getting-started.md)

---

## Documentation

### Guides et démarrage

| Document | Description |
|----------|-------------|
| [Guide de démarrage](docs/guides/getting-started.md) | Premier déploiement en 30 minutes |
| [Guide utilisateur](docs/guides/user-guide.md) | Utilisation de l'application |
| [Index des guides](docs/guides/README.md) | Tous les guides pratiques |

### Runbooks opérationnels

| Document | Description |
|----------|-------------|
| [Runbook PaaS](docs/runbooks/runbook-paas.md) | Procédure déploiement PaaS (15-20min) |
| [Runbook IaaS](docs/runbooks/runbook-iaas.md) | Procédure déploiement IaaS (30-35min) |
| [Runbook Destruction](docs/runbooks/runbook-destroy.md) | Suppression des ressources |
| [Index des runbooks](docs/runbooks/README.md) | Toutes les procédures |

### Troubleshooting

| Document | Description |
|----------|-------------|
| [PaaS Troubleshooting](docs/troubleshooting/paas-troubleshooting.md) | Dépannage Azure App Service |
| [IaaS Troubleshooting](docs/troubleshooting/iaas-troubleshooting.md) | Dépannage VM Scale Set |
| [CI/CD Troubleshooting](docs/troubleshooting/cicd-troubleshooting.md) | Dépannage GitHub Actions |
| [Index troubleshooting](docs/troubleshooting/README.md) | Tous les guides de dépannage |

### Operations et référence

| Document | Description |
|----------|-------------|
| [Scripts Reference](docs/operations/scripts-reference.md) | Documentation scripts et Makefile |
| [CI/CD Reference](docs/operations/cicd-reference.md) | Documentation GitHub Actions |
| [Daily Operations](docs/operations/daily-operations.md) | Opérations quotidiennes |
| [Architecture](docs/reference/architecture/overview.md) | Documentation architecturale |
| [Comparaison PaaS vs IaaS](docs/reference/comparison.md) | Analyse détaillée |
| [Index complet](docs/README.md) | Navigation complète

---

## 📜 Licence

Ce projet est destiné à des fins éducatives dans le cadre du cursus Epitech.

---

**Projet éducatif - Epitech 2025** | Made with ❤️ and ☕
