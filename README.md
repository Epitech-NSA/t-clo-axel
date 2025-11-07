# TERRACLOUD

Infrastructure as Code (IaC) sur Microsoft Azure - Comparaison PaaS vs IaaS

## Vue d'ensemble

TERRACLOUD est un projet d'infrastructure qui présente et compare deux approches de déploiement cloud pour une application web conteneurisée sur Microsoft Azure.

### Les deux approches

**PaaS (Platform as a Service)**
- Azure App Service pour l'hébergement
- Déploiement simplifié et automatisé
- Maintenance managée par Azure

**IaaS (Infrastructure as a Service)**
- VM Scale Set avec Load Balancer
- Contrôle total de l'infrastructure
- Configuration via Ansible

### Technologies utilisées

- **Application**: Laravel (PHP) avec MySQL
- **Conteneurisation**: Docker
- **Infrastructure as Code**: Terraform
- **Automatisation**: Ansible (IaaS)
- **Cloud Provider**: Microsoft Azure

## Objectifs pédagogiques

1. Comparer les approches PaaS et IaaS en situation réelle
2. Maîtriser Terraform pour l'infrastructure as code
3. Automatiser les déploiements avec Ansible
4. Implémenter les bonnes pratiques Azure
5. Gérer la scalabilité et la haute disponibilité

---

## Structure du projet

```
T-CLO-900/
├── terraform/                   # Infrastructure as Code
│   ├── envs/                    
│   │   ├── dev/                 # Environnement de développement
│   │   │   ├── infrastructure.tf    # Infrastructure partagée
│   │   │   ├── paas.tf             # Configuration PaaS
│   │   │   ├── iaas.tf             # Configuration IaaS
│   │   │   ├── variables.tf        # Variables
│   │   │   └── backend.tf          # Backend Terraform
│   │   └── prod/                # Environnement de production
│   └── modules/                 # Modules Terraform réutilisables
│       ├── rg/                  # Resource Group
│       ├── network/             # Réseau (VNet, Subnets, NSG)
│       ├── acr/                 # Container Registry
│       ├── mysql/               # Base de données MySQL
│       ├── appservice/          # App Service (PaaS)
│       ├── loadbalancer/        # Load Balancer (IaaS)
│       └── vmss/                # VM Scale Set (IaaS)
│
├── ansible/                     # Automatisation IaaS
│   ├── inventory/               # Inventaires dynamiques Azure
│   ├── playbooks/               # Playbooks de déploiement
│   ├── roles/                   # Rôles Ansible
│   └── group_vars/              # Variables de configuration
│
├── sample-app-master/           # Application Laravel
│   ├── Dockerfile               # Configuration Docker
│   └── ...                      # Code source de l'application
│
└── docs/                        # Documentation complète
    ├── README.md                # Index de la documentation
    ├── conventions.md           # Conventions de nommage
    ├── architecture/            # Documentation architecturale
    ├── deployment/              # Guides de déploiement
    └── guides/                  # Guides utilisateur
```

---

## Démarrage rapide

### Prérequis

| Outil | Version minimale | Usage |
|-------|-----------------|-------|
| [Azure CLI](https://learn.microsoft.com/fr-fr/cli/azure/install-azure-cli) | 2.40+ | Gestion Azure |
| [Terraform](https://developer.hashicorp.com/terraform) | 1.0+ | Infrastructure as Code |
| [Docker](https://docs.docker.com/get-docker/) | 20.10+ | Build des images |
| [Ansible](https://docs.ansible.com/) | 2.9+ | Automatisation (IaaS uniquement) |

### Configuration Azure

```bash
# Se connecter à Azure
az login

# Définir la subscription Epitech
az account set --subscription "6b9318b1-2215-418a-b0fd-ba0832e9b333"
```

**Informations importantes:**
- **Tenant**: Epitech
- **Subscription ID**: `6b9318b1-2215-418a-b0fd-ba0832e9b333`
- **Resource Group**: `rg-nan_1` (partagé, ne pas supprimer)
- **Région**: France Central

### Premier déploiement

Le guide de démarrage complet pour un accompagnement pas à pas:

**[Guide de démarrage rapide](docs/guides/getting-started.md)**

Ce guide inclut:
- Installation détaillée de tous les outils
- Configuration pas à pas
- Premier déploiement PaaS en 30 minutes
- Vérification et tests

---

## Déployer avec PaaS (App Service)

### Résumé de l'approche

L'approche PaaS utilise Azure App Service pour un déploiement simplifié et managé.

**Avantages:**
- Déploiement en 15 minutes
- Maintenance automatisée par Azure
- Scalabilité automatique
- Coût prévisible (~32€/mois en dev)

**Inconvénients:**
- Contrôle limité sur l'infrastructure
- Dépendance à la plateforme Azure
- Options de configuration limitées

### Déploiement rapide

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec votre mot de passe MySQL

terraform init
terraform apply -target=module.rg \
                -target=module.network \
                -target=module.acr \
                -target=module.mysql \
                -target=module.appservice

# Récupérer l'URL
terraform output webapp_url
```

**Documentation complète:** [docs/deployment/deployment-paas.md](docs/deployment/deployment-paas.md)

---

## Déployer avec IaaS (VM Scale Set)

### Résumé de l'approche

L'approche IaaS utilise des VMs dans un Scale Set avec Load Balancer pour un contrôle total.

**Avantages:**
- Contrôle complet de l'infrastructure
- Flexibilité maximale
- Configuration personnalisée
- Debugging approfondi possible

**Inconvénients:**
- Déploiement en 30-35 minutes
- Maintenance manuelle
- Configuration plus complexe
- Coût plus élevé (~103€/mois en dev)

### Déploiement rapide

```bash
# Générer une clé SSH
ssh-keygen -t ed25519 -f ~/.ssh/terracloud-dev-key

# Déployer l'infrastructure
cd terraform/envs/dev
export TF_VAR_ssh_public_key_iaas="$(cat ~/.ssh/terracloud-dev-key.pub)"
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars

terraform init
terraform apply -target=module.loadbalancer \
                -target=module.vmss

# Déployer l'application avec Ansible
cd ../../../ansible
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml

# Récupérer l'IP du Load Balancer
cd ../terraform/envs/dev
terraform output iaas_load_balancer_ip
```

**Documentation complète:** [docs/deployment/deployment-iaas.md](docs/deployment/deployment-iaas.md)

---

## Architecture

### Vue d'ensemble

Le projet implémente deux architectures parallèles partageant la même infrastructure de base:

**Infrastructure partagée:**
- Resource Group: `rg-nan_1`
- Virtual Network: `tc-dev-vnet-frc-01` (10.0.0.0/16)
- Azure Container Registry: `tcdevacrfrc01`
- MySQL Flexible Server: `tc-dev-mysql-frc-01`

**Architecture PaaS:**
```
Internet → App Service → ACR → MySQL
```

**Architecture IaaS:**
```
Internet → Load Balancer → VM Scale Set (2-5 VMs) → Docker → ACR → MySQL
```

**Documentation architecture complète:**
- [Vue d'ensemble architecturale](docs/architecture/overview.md)
- [Infrastructure partagée](docs/architecture/infrastructure-shared.md)
- [Architecture PaaS détaillée](docs/architecture/architecture-paas.md)
- [Architecture IaaS détaillée](docs/architecture/architecture-iaas.md)

---

## Comparaison PaaS vs IaaS

| Critère | PaaS (App Service) | IaaS (VMSS) |
|---------|-------------------|-------------|
| **Temps de déploiement** | 15 minutes | 30-35 minutes |
| **Complexité** | Faible | Élevée |
| **Contrôle infrastructure** | Limité | Total |
| **Maintenance** | Automatique | Manuelle |
| **Coût mensuel (dev)** | ~32€ | ~103€ |
| **Scalabilité** | Automatique | Configurable |
| **Cas d'usage idéal** | Applications standard | Besoins spécifiques |

**Analyse détaillée:** [docs/deployment/comparison.md](docs/deployment/comparison.md)

---

## Configuration

### Environnements

| Environnement | Code | Région | VNet CIDR | Disponibilité |
|---------------|------|--------|-----------|---------------|
| Développement | `dev` | France Central | 10.0.0.0/16 | 08:00-19:00 |
| Production | `prod` | France Central | 10.1.0.0/16 | 24/7 |

### Variables Terraform

Créer un fichier `terraform.tfvars` dans `terraform/envs/dev/` ou `terraform/envs/prod/`:

```hcl
# Obligatoire
mysql_admin_password = "VotreMotDePasseSecurise123!"
ssh_public_key_iaas  = "ssh-ed25519 AAAAC3Nza..." # Pour IaaS uniquement

# Optionnel (valeurs par défaut disponibles)
environment = "dev"
location    = "francecentral"
```

---

## Documentation

### Guides principaux

| Document | Description |
|----------|-------------|
| [Guide de démarrage](docs/guides/getting-started.md) | Premier déploiement en 30 minutes |
| [Guide utilisateur](docs/guides/user-guide.md) | Utilisation de l'application |
| [Déploiement PaaS](docs/deployment/deployment-paas.md) | Guide complet PaaS |
| [Déploiement IaaS](docs/deployment/deployment-iaas.md) | Guide complet IaaS |
| [Comparaison détaillée](docs/deployment/comparison.md) | Analyse PaaS vs IaaS |

### Documentation architecture

| Document | Description |
|----------|-------------|
| [Vue d'ensemble](docs/architecture/overview.md) | Architecture générale |
| [Infrastructure partagée](docs/architecture/infrastructure-shared.md) | Ressources communes |
| [Architecture PaaS](docs/architecture/architecture-paas.md) | Détails PaaS |
| [Architecture IaaS](docs/architecture/architecture-iaas.md) | Détails IaaS |

### Références

- [Conventions de nommage](docs/conventions.md) - Standards Azure du projet
- [Index complet de la documentation](docs/README.md) - Navigation complète

---

## Nettoyage des ressources

**Détruire uniquement le PaaS:**
```bash
cd terraform/envs/dev
terraform destroy -target=module.appservice
```

**Détruire uniquement l'IaaS:**
```bash
cd terraform/envs/dev
terraform destroy -target=module.vmss -target=module.loadbalancer
```

**Détruire toute l'infrastructure:**
```bash
cd terraform/envs/dev
terraform destroy
```

**Important:** Le Resource Group `rg-nan_1` est partagé et ne doit jamais être supprimé.

---

## Dépannage rapide

| Problème | Solution rapide |
|----------|----------------|
| Terraform state lock | `terraform force-unlock <LOCK_ID>` |
| Ansible unreachable | Vérifier que les VMs sont démarrées |
| App Service 503 | Attendre 2-3 min, consulter les logs |
| MySQL connexion refusée | Vérifier les firewall rules |

**Documentation complète du dépannage:**
- [Dépannage PaaS](docs/deployment/deployment-paas.md#dépannage)
- [Dépannage IaaS](docs/deployment/deployment-iaas.md#dépannage)

---

## Informations projet

### Contexte

Projet réalisé dans le cadre du cursus Epitech - T-CLO-900

### Informations Azure

- **Tenant**: Epitech
- **Subscription**: Sub T-CLO (`6b9318b1-2215-418a-b0fd-ba0832e9b333`)
- **Resource Group**: `rg-nan_1` (partagé)
- **Région principale**: France Central

### Standards et conventions

Toutes les ressources suivent les conventions de nommage Azure et incluent les tags standards TERRACLOUD. Voir [docs/conventions.md](docs/conventions.md) pour les détails.

---

## Ressources externes

### Documentation Azure

- [Azure App Service](https://learn.microsoft.com/fr-fr/azure/app-service/)
- [Azure VM Scale Sets](https://learn.microsoft.com/fr-fr/azure/virtual-machine-scale-sets/)
- [Azure Container Registry](https://learn.microsoft.com/fr-fr/azure/container-registry/)

### Documentation outils

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Azure Collection](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/index.html)
- [Laravel Documentation](https://laravel.com/docs)

---

**Projet éducatif - Epitech 2025**
