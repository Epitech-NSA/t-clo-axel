# Troubleshooting CI/CD - GitHub Actions

Ce guide résout les problèmes courants avec les workflows GitHub Actions.

## Table des matières

1. [Erreur Login Azure failed](#erreur-login-azure-failed)
2. [ACR login failed](#acr-login-failed)
3. [SSH connection refused (IaaS)](#ssh-connection-refused-iaas)
4. [Workflow bloqué en attente d'approbation](#workflow-bloqué-en-attente-dapprobation)
5. [Terraform state lock](#terraform-state-lock)
6. [Build Docker échoue](#build-docker-échoue)
7. [Déploiement timeout](#déploiement-timeout)

## Erreur Login Azure failed

### Symptôme

```
Error: Login failed
```

### Diagnostic

Le Service Principal Azure utilisé par GitHub Actions est invalide ou expiré.

### Solutions

#### Solution 1: Vérifier les credentials

```bash
# Récupérer les credentials depuis GitHub Secrets
# Settings → Secrets and variables → Actions → AZURE_CREDENTIALS

# Tester localement
az login --service-principal \
  -u <clientId> \
  -p <clientSecret> \
  --tenant <tenantId>
```

#### Solution 2: Régénérer le Service Principal

```bash
# Régénérer les credentials
az ad sp credential reset --id <clientId>

# Ou recréer complètement
az ad sp create-for-rbac \
  --name "github-actions-terracloud" \
  --role Contributor \
  --scopes /subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333 \
  --sdk-auth > azure-credentials.json

# Mettre à jour le secret AZURE_CREDENTIALS dans GitHub
cat azure-credentials.json
```

#### Solution 3: Vérifier les permissions

```bash
# Lister les rôles du SP
az role assignment list --assignee <clientId> --output table

# Ajouter le rôle Contributor si manquant
az role assignment create \
  --assignee <clientId> \
  --role Contributor \
  --scope /subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333
```

---

## ACR login failed

### Symptôme

```
Error: ACR login failed
```

### Diagnostic

Le Service Principal n'a pas les permissions pour pusher vers ACR.

### Solutions

#### Solution 1: Ajouter le rôle AcrPush

```bash
SP_ID=$(az ad sp list --display-name "github-actions-terracloud" --query "[0].appId" -o tsv)

# Pour dev
az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope /subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333/resourceGroups/rg-nan_1/providers/Microsoft.ContainerRegistry/registries/tcdevacrfrc01

# Pour prod
az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope /subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333/resourceGroups/rg-nan_1/providers/Microsoft.ContainerRegistry/registries/tcprodacrfrc01
```

#### Solution 2: Vérifier que l'ACR existe

```bash
az acr show --name tcdevacrfrc01 --resource-group rg-nan_1
```

---

## SSH connection refused (IaaS)

### Symptôme

```
Error: SSH connection refused during IaaS deployment
```

### Diagnostic

Les clés SSH configurées dans GitHub Secrets sont incorrectes ou mal formatées.

### Solutions

#### Solution 1: Vérifier le format des clés

```bash
# La clé privée doit être en format OpenSSH
cat ~/.ssh/id_ed25519
# Doit commencer par: -----BEGIN OPENSSH PRIVATE KEY-----

# Si en format PEM, convertir
ssh-keygen -p -f ~/.ssh/id_ed25519 -m pem
```

#### Solution 2: Re-encoder la clé pour GitHub Secrets

```bash
# Copier la clé complète y compris BEGIN/END
cat ~/.ssh/id_ed25519

# Dans GitHub Secrets:
# Settings → Secrets → SSH_PRIVATE_KEY
# Coller tout le contenu (avec les lignes BEGIN et END)
```

#### Solution 3: Vérifier le NSG

```bash
az network nsg rule show \
  --nsg-name nsg-vmss \
  --resource-group rg-nan_1 \
  --name Allow-SSH-Inbound
```

---

## Workflow bloqué en attente d'approbation

### Symptôme

```
Waiting for approval
```

### Diagnostic

L'environnement GitHub (dev/prod) nécessite une approbation manuelle.

### Solutions

#### Solution 1: Approuver le déploiement

1. Aller dans **Actions** → Workflow en cours
2. Cliquer sur **Review deployments**
3. Cocher l'environnement et cliquer sur **Approve and deploy**

#### Solution 2: Désactiver l'approbation (dev uniquement)

1. **Settings** → **Environments** → **dev**
2. Décocher **Required reviewers**
3. Sauvegarder

**⚠️ Ne PAS faire cela pour la production!**

---

## Terraform state lock

### Symptôme

```
Error: Error acquiring the state lock
```

### Diagnostic

Un déploiement précédent a été interrompu et le state est verrouillé.

### Solutions

#### Solution 1: Attendre

Si un autre workflow est en cours, attendre qu'il se termine (10-15 minutes max).

#### Solution 2: Forcer le unlock

**⚠️ Utiliser avec précaution!**

1. Identifier le LOCK_ID dans les logs du workflow
2. Exécuter localement:

```bash
cd terraform
terraform force-unlock <LOCK_ID>
```

3. Relancer le workflow

---

## Build Docker échoue

### Symptôme

```
Error: Docker build failed
```

### Diagnostic

Erreur lors du build de l'image Docker.

### Solutions

#### Solution 1: Vérifier le Dockerfile

```bash
# Tester localement
cd sample-app-master/
docker build -t test:latest .

# Consulter les logs d'erreur
```

#### Solution 2: Problème de dépendances

Vérifier `composer.json`, `package.json` et autres fichiers de dépendances.

#### Solution 3: Timeout

Le build prend trop de temps (>60 minutes).

```yaml
# Dans le workflow, augmenter le timeout
jobs:
  build:
    timeout-minutes: 90
```

---

## Déploiement timeout

### Symptôme

```
Error: The job running on runner GitHub Actions X has exceeded the maximum execution time
```

### Diagnostic

Le déploiement prend plus de 6 heures (limite GitHub Actions gratuit).

### Solutions

#### Solution 1: Augmenter le timeout

```yaml
# Dans le workflow
jobs:
  deploy:
    timeout-minutes: 120  # 2 heures
```

#### Solution 2: Déployer en local

Si le problème persiste, déployer localement:

```bash
make dev-paas  # ou make dev-iaas
```

---

## Problèmes courants supplémentaires

### Workflow ne se déclenche pas

**Causes**:
- Branch non surveillée (pas main ou develop)
- Fichier workflow invalide (YAML mal formé)
- Actions désactivées sur le repo

**Solution**:
```bash
# Vérifier la syntaxe YAML
yamllint .github/workflows/deploy-paas.yml

# Vérifier que Actions est activé
# Settings → Actions → General → Actions permissions
```

### Secret non trouvé

**Symptôme**: `Error: Secret MYSQL_PASSWORD not found`

**Solution**:
```bash
# Vérifier que le secret existe
# Settings → Secrets and variables → Actions

# Ajouter le secret manquant
```

### Environnement non trouvé

**Symptôme**: `Error: Environment 'dev' not found`

**Solution**:
```bash
# Créer l'environnement
# Settings → Environments → New environment
# Nom: dev (ou prod)
```

---

## Bonnes pratiques

### 1. Tester localement d'abord

Avant de pusher, tester:
```bash
make validate
make plan-paas ENV=dev
```

### 2. Utiliser dry-run

Toujours tester avec dry_run: true avant un vrai déploiement.

### 3. Surveiller les logs

Consulter les logs en temps réel pendant le déploiement.

### 4. Limiter les déclencheurs

Ne pas déclencher les workflows sur chaque commit (utiliser pull_request).

---

## Références

- [Guide CI/CD](../operations/cicd-reference.md)
- [Runbook PaaS](../runbooks/runbook-paas.md)
- [Runbook IaaS](../runbooks/runbook-iaas.md)
- [Problèmes communs](common-issues.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

Pour des problèmes non couverts:
1. Consulter les logs GitHub Actions
2. Vérifier [les problèmes communs](common-issues.md)
3. Tester localement
4. Ouvrir une issue

