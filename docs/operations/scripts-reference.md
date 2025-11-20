# Référence des Scripts - TERRACLOUD

Documentation de référence pour tous les scripts bash et le Makefile.

## Vue d'ensemble

```
scripts/
├── common/                  # Utilitaires partagés
│   ├── colors.sh           # Définitions de couleurs
│   ├── logging.sh          # Fonctions de logging
│   └── checks.sh           # Vérifications de prérequis
├── setup-environment.sh     # Installation des dépendances
├── build-push-image.sh      # Build et push Docker
├── deploy-paas.sh          # Déploiement PaaS
├── deploy-iaas.sh          # Déploiement IaaS
└── destroy-environment.sh  # Nettoyage des ressources
```

## Scripts utilitaires

### `common/colors.sh`

Définit les couleurs pour les sorties terminal.

**Variables**: `RED`, `GREEN`, `YELLOW`, `BLUE`, `PURPLE`, `CYAN`, `WHITE`, `NC`

**Usage**:
```bash
source scripts/common/colors.sh
echo -e "${GREEN}Succès!${NC}"
```

### `common/logging.sh`

Fonctions de logging standardisées.

**Fonctions principales**:
- `log_info "message"` - Information
- `log_success "message"` - Succès
- `log_warning "message"` - Avertissement
- `log_error "message"` - Erreur
- `log_step "message"` - Étape en cours

**Fonctions avancées**:
- `show_spinner PID "message"` - Spinner pendant une commande
- `progress_bar current total` - Barre de progression
- `confirm "question" "default"` - Confirmation utilisateur

### `common/checks.sh`

Vérifications de prérequis.

**Fonctions principales**:
- `command_exists cmd` - Vérifie si une commande existe
- `check_all_prerequisites type` - Vérifie tous les prérequis (paas/iaas/all)
- `check_azure_cli` - Vérifie Azure CLI
- `check_terraform` - Vérifie Terraform
- `check_ansible` - Vérifie Ansible
- `check_docker` - Vérifie Docker

## Scripts de déploiement

### `setup-environment.sh`

Configure l'environnement de développement complet.

**Usage**: `./scripts/setup-environment.sh`

**Actions**: Installation des dépendances, configuration Azure CLI, initialisation Terraform et Ansible.

---

### `build-push-image.sh`

Build et push l'image Docker vers ACR.

**Usage**: `./scripts/build-push-image.sh [environment] [tag]`

**Arguments**:
- `environment`: dev (défaut) ou prod
- `tag`: Tag Docker optionnel

**Exemples**:
```bash
./scripts/build-push-image.sh dev
./scripts/build-push-image.sh prod v1.2.3
make build-push ENV=dev
```

---

### `deploy-paas.sh`

Déploie l'application sur Azure App Service.

**Usage**: `./scripts/deploy-paas.sh [environment]`

**Variables d'environnement**:
- `DRY_RUN=true` - Mode plan uniquement

**Exemples**:
```bash
./scripts/deploy-paas.sh dev
DRY_RUN=true ./scripts/deploy-paas.sh dev
make dev-paas
```

---

### `deploy-iaas.sh`

Déploie l'application sur VMSS avec Ansible.

**Usage**: `./scripts/deploy-iaas.sh [environment]`

**Variables d'environnement**:
- `DRY_RUN=true` - Mode plan uniquement
- `SETUP_HTTPS=false` - Désactiver HTTPS

**Exemples**:
```bash
./scripts/deploy-iaas.sh dev
SETUP_HTTPS=false ./scripts/deploy-iaas.sh dev
make dev-iaas
```

---

### `destroy-environment.sh`

Détruit les ressources Azure.

**Usage**: `./scripts/destroy-environment.sh [environment] [component]`

**Arguments**:
- `environment`: dev ou prod
- `component`: paas, iaas, ou all

**⚠️ ATTENTION**: Action irréversible!

**Exemples**:
```bash
./scripts/destroy-environment.sh dev paas
make destroy-dev COMPONENT=all
```

## Scripts de test

### Tests disponibles

| Script | Description | Usage |
|--------|-------------|-------|
| `test-paas.sh` | Teste le déploiement PaaS | `./tests/test-paas.sh dev` |
| `test-iaas.sh` | Teste le déploiement IaaS | `./tests/test-iaas.sh dev` |
| `test-https.sh` | Teste la configuration SSL | `./tests/test-https.sh` |
| `test-database.sh` | Teste la connectivité MySQL | `./tests/test-database.sh dev` |

## Makefile

### Commandes principales

#### Setup et Build
```bash
make setup                   # Installer l'environnement
make build ENV=dev           # Build image
make push ENV=dev            # Push image
make build-push ENV=dev      # Build et push
```

#### Déploiement
```bash
make dev-paas                # Déployer PaaS en dev
make dev-iaas                # Déployer IaaS en dev
make dev-iaas-no-https       # IaaS sans HTTPS
make prod-paas               # Déployer PaaS en prod
make prod-iaas               # Déployer IaaS en prod
```

#### Infrastructure
```bash
make validate                # Valider Terraform
make plan-paas ENV=dev       # Plan PaaS
make plan-iaas ENV=dev       # Plan IaaS
make destroy-dev COMPONENT=paas
make destroy-prod COMPONENT=all
```

#### Tests
```bash
make test-paas ENV=dev
make test-iaas ENV=dev
make test-https
make test-db ENV=dev
```

#### Monitoring
```bash
make logs-paas ENV=dev       # Logs PaaS
make logs-iaas ENV=dev       # Logs IaaS
make status ENV=dev          # Statut des ressources
make urls ENV=dev            # Afficher les URLs
```

#### SSH
```bash
make ssh-paas ENV=dev        # SSH vers App Service
make ssh-iaas ENV=dev        # SSH vers VMSS
```

#### Utilitaires
```bash
make clean                   # Nettoyer fichiers temporaires
make fmt                     # Formater Terraform
make info                    # Infos projet
make help                    # Aide
```

### Variables Makefile

| Variable | Description | Exemple |
|----------|-------------|---------|
| `ENV` | Environnement cible | `ENV=dev` ou `ENV=prod` |
| `COMPONENT` | Composant pour destroy | `COMPONENT=paas` |
| `DOCKER_TAG` | Tag Docker personnalisé | `DOCKER_TAG=v1.0.0` |

## Workflows types

### Premier déploiement PaaS
```bash
make setup
make build-push ENV=dev
make dev-paas
make test-paas ENV=dev
```

### Premier déploiement IaaS
```bash
make setup
ssh-keygen -t ed25519 -f ~/.ssh/terracloud-dev-key
make build-push ENV=dev
make dev-iaas
make test-iaas ENV=dev
```

### Mise à jour d'application
```bash
# Modifier le code
make build-push ENV=dev
make dev-paas  # ou make dev-iaas
make test-paas ENV=dev
```

### Nettoyage complet
```bash
make destroy-dev COMPONENT=all
make clean
```

## Variables d'environnement

### Fichier .env.local

```bash
# Configuration dans config/.env.local
MYSQL_ADMIN_PASSWORD="VotreMotDePasse"
SSH_PUBLIC_KEY_IAAS="ssh-ed25519 AAA..."
```

### Export manuel

```bash
export MYSQL_ADMIN_PASSWORD="VotreMotDePasse"
export SSH_PUBLIC_KEY_IAAS="$(cat ~/.ssh/terracloud-dev-key.pub)"
export TF_VAR_mysql_admin_password="$MYSQL_ADMIN_PASSWORD"
```

## Bonnes pratiques

### 1. Toujours exécuter depuis la racine

```bash
cd /home/axel/Epitech/T-CLO-900
./scripts/deploy-paas.sh dev
```

### 2. Utiliser le Makefile

Le Makefile simplifie et standardise les commandes.

```bash
# Préférer
make dev-paas

# Au lieu de
cd terraform && terraform workspace select dev && terraform apply ...
```

### 3. Tester en dry-run

```bash
DRY_RUN=true ./scripts/deploy-paas.sh dev
make plan-paas ENV=dev
```

### 4. Versionner les images

```bash
make build-push ENV=prod DOCKER_TAG=v1.2.3
```

### 5. Monitoring après déploiement

```bash
make status ENV=dev
make logs-paas ENV=dev
make test-paas ENV=dev
```

## Références

- [Runbooks](../runbooks/README.md) - Procédures opérationnelles
- [Troubleshooting Scripts](../troubleshooting/scripts-troubleshooting.md) - Dépannage
- [Opérations quotidiennes](daily-operations.md) - Tâches courantes

## Support

En cas de problème, consultez le [guide de troubleshooting des scripts](../troubleshooting/scripts-troubleshooting.md).

