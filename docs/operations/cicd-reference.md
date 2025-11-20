# Référence CI/CD - GitHub Actions

Documentation de référence pour les workflows GitHub Actions.

## Vue d'ensemble

```
.github/workflows/
├── docker-build.yml          # Build et push Docker
├── deploy-paas.yml           # Déploiement PaaS
├── deploy-iaas.yml           # Déploiement IaaS
└── terraform-validate.yml    # Validation Terraform sur PR
```

## Workflows disponibles

### 1. Docker Build (`docker-build.yml`)

Build et push automatique des images Docker vers ACR.

**Déclencheurs**:
- Push sur `main` ou `develop`
- Pull Request vers `main` ou `develop`
- Manuel (`workflow_dispatch`)

**Actions**:
1. Checkout du code
2. Configuration Docker Buildx
3. Login Azure et ACR
4. Build et push de l'image
5. Scan de sécurité (Trivy)
6. Upload des résultats sécurité

**Tags générés**:
- `latest` - Dernier build
- `stable` - Production (main uniquement)
- `{sha}-{timestamp}` - Version précise

---

### 2. Terraform Validate (`terraform-validate.yml`)

Validation automatique du code Terraform sur PR.

**Déclencheurs**:
- Pull Request vers `main` ou `develop`
- Manuel

**Actions**:
1. `terraform fmt` check
2. `terraform init`
3. `terraform validate`
4. Scan de sécurité (tfsec)
5. Commentaire automatique sur la PR

---

### 3. Deploy PaaS (`deploy-paas.yml`)

Déploiement automatisé sur Azure App Service.

**Déclencheurs**: Manuel uniquement

**Paramètres**:
- `environment`: dev ou prod
- `dry_run`: true (plan) ou false (apply)

**Actions**:
1. Terraform init et workspace selection
2. Terraform plan
3. Terraform apply (si dry_run=false)
4. Health check
5. Résumé du déploiement

**Ressources déployées**:
- Resource Group
- Virtual Network
- Container Registry
- MySQL Flexible Server
- App Service Plan
- App Service

---

### 4. Deploy IaaS (`deploy-iaas.yml`)

Déploiement automatisé sur VMSS avec Ansible.

**Déclencheurs**: Manuel uniquement

**Paramètres**:
- `environment`: dev ou prod
- `dry_run`: true (plan) ou false (apply)
- `setup_https`: true ou false

**Actions**:
1. Terraform infrastructure
2. Attente initialisation VMSS
3. Ansible: Installation Docker
4. Ansible: Déploiement application
5. Ansible: Configuration HTTPS (optionnel)
6. Health check

**Ressources déployées**:
- Resource Group
- Virtual Network
- Container Registry
- MySQL Flexible Server
- VM Scale Set
- Public IPs
- NSG

## Configuration des Secrets

### Secrets GitHub requis

| Secret | Description | Usage |
|--------|-------------|-------|
| `AZURE_CREDENTIALS` | Service Principal JSON | Tous workflows |
| `MYSQL_PASSWORD` | Mot de passe MySQL | Déploiements |
| `SSH_PRIVATE_KEY` | Clé SSH privée | IaaS uniquement |
| `SSH_PUBLIC_KEY` | Clé SSH publique | IaaS uniquement |

### Création du Service Principal

```bash
# Créer le Service Principal
az ad sp create-for-rbac \
  --name "github-actions-terracloud" \
  --role Contributor \
  --scopes /subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333 \
  --sdk-auth > azure-credentials.json

# Ajouter permissions ACR
SP_ID=$(az ad sp list --display-name "github-actions-terracloud" --query "[0].appId" -o tsv)

az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope /subscriptions/.../registries/tcdevacrfrc01
```

### Génération des clés SSH

```bash
# Générer une paire de clés
ssh-keygen -t ed25519 -f ~/.ssh/terracloud_deploy -C "github-actions"

# Clé privée → SSH_PRIVATE_KEY
cat ~/.ssh/terracloud_deploy

# Clé publique → SSH_PUBLIC_KEY  
cat ~/.ssh/terracloud_deploy.pub
```

## Environnements GitHub

### Configuration recommandée

**Settings** → **Environments** → Créer `dev` et `prod`

#### Pour `prod`:
- **Required reviewers**: Au moins 1 personne
- **Deployment branches**: `main` uniquement
- **Environment secrets**: Secrets spécifiques à prod

## Utilisation

### Déploiement complet (dev)

1. **Commit et push**:
```bash
git commit -m "feat: nouvelle fonctionnalité"
git push origin develop
```
→ Build automatique de l'image Docker

2. **Déployer**:
- Aller dans **Actions** → **Deploy PaaS** (ou **Deploy IaaS**)
- Cliquer **Run workflow**
- Sélectionner:
  - Environment: `dev`
  - Dry run: `false`
  - Setup HTTPS: `true` (IaaS uniquement)
- Cliquer **Run workflow**

### Déploiement en production

1. **Merger vers main**:
```bash
git checkout main
git merge develop
git push origin main
```
→ Build automatique avec tag "stable"

2. **Déployer**:
- Actions → Deploy PaaS/IaaS → Run workflow
- Environment: `prod`
- Dry run: `false`
- **Attendre l'approbation** (si environnement protégé)

### Dry-run (Test sans déploiement)

- Actions → Deploy → Run workflow
- Dry run: `true`
- Consulter les logs pour voir le plan Terraform

## Stratégie de branches

```
main (production)
  ↑
develop (staging)
  ↑
feature/xxx (développement)
```

### Workflow Git

1. **feature/** - Développement de fonctionnalités
2. **develop** - Intégration et tests
3. **main** - Production stable

### Tags Docker

- `latest` - Dernier build (toutes branches)
- `stable` - Production (main uniquement)
- `{sha}-{timestamp}` - Version précise pour rollback

## Bonnes pratiques

### 1. Tests avant déploiement

```bash
# 1. Valider Terraform localement
make validate

# 2. Test en dry-run via GitHub Actions
# Dry run: true

# 3. Déploiement réel
# Dry run: false
```

### 2. Monitoring post-déploiement

- Consulter les logs GitHub Actions
- Vérifier l'application déployée
- Exécuter les tests automatisés

### 3. Rollback rapide

**Option 1**: Redéployer une version antérieure
```bash
# 1. Identifier le SHA du commit stable
git log --oneline

# 2. Checkout le commit
git checkout <sha>

# 3. Redéployer via GitHub Actions
```

**Option 2**: Changer le tag Docker (PaaS)
```bash
az webapp config container set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --docker-custom-image-name tcdevacrfrc01.azurecr.io/sample-app:<old-tag>
```

### 4. Sécurité

- ✅ Toujours utiliser des secrets GitHub
- ✅ Activer l'approbation manuelle pour prod
- ✅ Limiter les permissions du Service Principal
- ✅ Rotater régulièrement les credentials (3-6 mois)
- ✅ Activer les scans de sécurité (Trivy, tfsec)
- ✅ Utiliser des environnements séparés (dev/prod)

## Améliorations futures

### Features souhaitées

- Notifications Slack/Teams sur les déploiements
- Tests d'intégration automatiques
- Blue/Green deployment
- Canary releases
- Rollback automatique en cas d'échec
- Estimation des coûts avec Infracost

## Références

- [Troubleshooting CI/CD](../troubleshooting/cicd-troubleshooting.md)
- [Runbooks](../runbooks/README.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure DevOps Best Practices](https://learn.microsoft.com/en-us/azure/devops/)

## Support

En cas de problème:
1. Consulter les logs GitHub Actions
2. Consulter le [troubleshooting CI/CD](../troubleshooting/cicd-troubleshooting.md)
3. Tester localement
4. Ouvrir une issue

