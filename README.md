# TERRACLOUD - Infrastructure as Code (IaC) sur Azure

## Objectif du projet
Ce projet étudiant a pour but de comparer **deux approches de déploiement d’une application web sur Azure** :
- **PaaS (Platform as a Service)** avec App Service + ACR
- **IaaS (Infrastructure as a Service)** avec VM + Docker + Ansible

---

## Organisation du projet
- `docs/` → Documentation (conventions, schémas, comparatifs)
- `terraform/` → Code Terraform
  - `envs/` → Déploiements par environnement (`dev`, `prod`)
  - `modules/` → Modules Terraform réutilisables (réseau, VM, App Service, etc.)

---

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform) → Infrastructure as Code
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) → Gestion Azure
- [Ansible](https://www.ansible.com/) → Provisionnement des VM
- [Docker](https://www.docker.com/) → Conteneurisation
- Accès au tenant **Epitech**, subscription `Sub T-CLO`, resource group `rg-nan_1`

---

## Conventions

Détails dans [docs/conventions.md](docs/conventions.md)