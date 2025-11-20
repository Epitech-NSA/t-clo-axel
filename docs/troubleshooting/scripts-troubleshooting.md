# Troubleshooting Scripts - Bash & Makefile

Ce guide résout les problèmes courants avec les scripts bash et le Makefile.

## Table des matières

1. [Script ne trouve pas les fonctions](#script-ne-trouve-pas-les-fonctions)
2. [Permissions Azure insuffisantes](#permissions-azure-insuffisantes)
3. [Problèmes de clés SSH](#problèmes-de-clés-ssh)
4. [Variables d'environnement manquantes](#variables-denvironnement-manquantes)
5. [Commandes Make échouent](#commandes-make-échouent)

## Script ne trouve pas les fonctions

### Symptôme

```bash
./scripts/deploy-paas.sh
# Error: log_info: command not found
```

### Diagnostic

Les scripts utilitaires ne sont pas sourcés correctement.

### Solutions

#### Solution 1: Vérifier les permissions

```bash
# Rendre tous les scripts exécutables
chmod +x scripts/*.sh scripts/common/*.sh
```

#### Solution 2: Vérifier les paths

```bash
# Les scripts utilisent $SCRIPT_DIR
# Vérifier qu'il est correctement défini
grep "SCRIPT_DIR" scripts/deploy-paas.sh
```

#### Solution 3: Exécuter depuis la racine du projet

```bash
# Toujours exécuter depuis la racine
cd /home/axel/Epitech/T-CLO-900
./scripts/deploy-paas.sh dev

# PAS depuis le dossier scripts
```

---

## Permissions Azure insuffisantes

### Symptôme

```bash
./scripts/deploy-paas.sh dev
# Error: (AuthorizationFailed) The client ... does not have authorization
```

### Diagnostic

L'utilisateur Azure connecté n'a pas les permissions nécessaires.

### Solutions

#### Solution 1: Vérifier la connexion

```bash
# Vérifier le compte actuel
az account show

# Vérifier la subscription
az account show --query "id" -o tsv
# Doit être: 6b9318b1-2215-418a-b0fd-ba0832e9b333
```

#### Solution 2: Se reconnecter

```bash
# Logout et login
az logout
az login

# Définir la bonne subscription
az account set --subscription "6b9318b1-2215-418a-b0fd-ba0832e9b333"
```

#### Solution 3: Vérifier les rôles

```bash
# Lister vos rôles
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table

# Vous devez avoir au minimum "Contributor"
```

---

## Problèmes de clés SSH

### Symptôme

```bash
./scripts/deploy-iaas.sh dev
# Error: Permission denied (publickey)
```

### Diagnostic

Les clés SSH sont manquantes ou mal configurées.

### Solutions

#### Solution 1: Vérifier le format de la clé

```bash
cat ~/.ssh/id_ed25519
# Doit commencer par: -----BEGIN OPENSSH PRIVATE KEY-----

# Si vide ou format incorrect, régénérer
ssh-keygen -t ed25519 -f ~/.ssh/terracloud-dev-key -C "terracloud"
```

#### Solution 2: Vérifier les permissions

```bash
# Permissions strictes requises
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/terracloud-dev-key
chmod 644 ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/terracloud-dev-key.pub

# Vérifier
ls -la ~/.ssh/
```

#### Solution 3: Utiliser ssh-agent

```bash
# Démarrer ssh-agent
eval "$(ssh-agent -s)"

# Ajouter la clé
ssh-add ~/.ssh/terracloud-dev-key

# Vérifier
ssh-add -l
```

---

## Variables d'environnement manquantes

### Symptôme

```bash
./scripts/deploy-paas.sh
# Error: MYSQL_PASSWORD not set
```

### Diagnostic

Les variables d'environnement requises ne sont pas définies.

### Solutions

#### Solution 1: Créer le fichier .env.local

```bash
# Copier le template
cp config/secrets.template config/.env.local

# Éditer avec vos valeurs
nano config/.env.local
```

#### Solution 2: Exporter les variables

```bash
# Exporter manuellement
export MYSQL_ADMIN_PASSWORD="VotreMotDePasse"
export SSH_PUBLIC_KEY_IAAS="$(cat ~/.ssh/terracloud-dev-key.pub)"

# Vérifier
echo $MYSQL_ADMIN_PASSWORD
```

#### Solution 3: Utiliser les variables Terraform

```bash
# Les scripts utilisent terraform.tfvars
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

---

## Commandes Make échouent

### Symptôme

```bash
make dev-paas
# make: *** No rule to make target 'dev-paas'. Stop.
```

### Diagnostic

Le Makefile n'est pas trouvé ou est mal formé.

### Solutions

#### Solution 1: Exécuter depuis la racine

```bash
# Toujours depuis la racine du projet
cd /home/axel/Epitech/T-CLO-900
make dev-paas
```

#### Solution 2: Vérifier que le Makefile existe

```bash
ls -la Makefile
# Doit exister

# Si absent, le projet est incomplet
```

#### Solution 3: Lister les commandes disponibles

```bash
# Voir toutes les commandes Make
make help
```

#### Solution 4: Variables Make manquantes

```bash
# Certaines commandes requièrent des variables
make destroy-dev COMPONENT=paas
make test-paas ENV=dev

# Sans les variables, la commande échoue
```

---

## Problèmes courants supplémentaires

### Script s'arrête sans erreur

**Cause**: `set -e` dans le script arrête l'exécution à la première erreur.

**Solution**: Consulter les logs juste avant l'arrêt.

### Timeout lors du build Docker

**Cause**: Connexion internet lente ou image trop volumineuse.

**Solution**:
```bash
# Augmenter le timeout Docker
export DOCKER_CLIENT_TIMEOUT=300
export COMPOSE_HTTP_TIMEOUT=300
```

### Le script demande une confirmation

**Cause**: Terraform ou autre commande attend un `yes`.

**Solution**:
```bash
# Utiliser -auto-approve (avec précaution)
terraform apply -auto-approve

# Ou activer dans le script
export TF_INPUT=false
```

### Couleurs ne s'affichent pas

**Cause**: Terminal ne supporte pas les couleurs ANSI.

**Solution**:
```bash
# Désactiver les couleurs
export NO_COLOR=1
./scripts/deploy-paas.sh dev
```

---

## Debugging des scripts

### Activer le mode debug

```bash
# Exécuter en mode verbose
bash -x ./scripts/deploy-paas.sh dev

# Ou ajouter dans le script
set -x  # Active le debug
# ... commandes ...
set +x  # Désactive le debug
```

### Vérifier les variables

```bash
# Ajouter des echo dans le script
echo "DEBUG: MYSQL_PASSWORD=$MYSQL_PASSWORD"
echo "DEBUG: CURRENT_DIR=$(pwd)"
```

### Logs détaillés

```bash
# Rediriger vers un fichier log
./scripts/deploy-paas.sh dev 2>&1 | tee deploy.log
```

---

## Références

- [Guide des scripts](../operations/scripts-reference.md)
- [Runbook PaaS](../runbooks/runbook-paas.md)
- [Runbook IaaS](../runbooks/runbook-iaas.md)
- [Problèmes communs](common-issues.md)

## Support

Pour des problèmes non couverts:
1. Activer le mode debug (`bash -x`)
2. Vérifier les logs
3. Consulter [les problèmes communs](common-issues.md)
4. Tester les commandes manuellement

