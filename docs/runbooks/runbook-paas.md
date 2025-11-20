# Runbook: Déploiement PaaS - Azure App Service

## Objectif

Déployer l'application Laravel sur Azure App Service en utilisant l'approche PaaS.

**Durée estimée**: 15-20 minutes

## Prérequis

### Outils requis

- Azure CLI 2.40+
- Terraform 1.0+
- Docker 20.10+
- Git 2.30+

### Accès Azure

- Subscription ID: `6b9318b1-2215-418a-b0fd-ba0832e9b333`
- Resource Group: `rg-nan_1`
- Région: France Central

### Vérification

```bash
az --version
terraform --version
docker --version
az account show
```

## Procédure de déploiement

### Étape 1: Configuration initiale

```bash
# Se connecter à Azure
az login
az account set --subscription "6b9318b1-2215-418a-b0fd-ba0832e9b333"

# Cloner le projet
git clone https://github.com/Epitech-NSA/t-clo-axel
cd t-clo-axel
```

**Checkpoint**: Connexion Azure établie

### Étape 2: Configuration Terraform

```bash
cd terraform

# Créer le workspace
terraform workspace new dev  # ou prod
terraform workspace select dev

# Configurer les variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Variables minimales requises:

```hcl
mysql_admin_password = "VotreMotDePasseSecurise123!"
environment = "dev"
location    = "francecentral"
```

**Checkpoint**: Variables configurées

### Étape 3: Initialisation Terraform

```bash
terraform init
terraform validate
```

**Checkpoint**: Terraform initialisé

### Étape 4: Build et push de l'image Docker

```bash
# Retour à la racine
cd ..

# Login ACR
az acr login --name tcdevacrfrc01

# Build et push
cd sample-app-master/
docker build -t tcdevacrfrc01.azurecr.io/sample-app:latest .
docker push tcdevacrfrc01.azurecr.io/sample-app:latest

# Vérification
az acr repository show-tags --name tcdevacrfrc01 --repository sample-app

cd ..
```

**Checkpoint**: Image Docker disponible dans ACR

### Étape 5: Planifier le déploiement

```bash
cd terraform

# Plan l'infrastructure PaaS
terraform plan -target=module.rg \
               -target=module.network \
               -target=module.acr \
               -target=module.mysql \
               -target=module.appservice
```

**Checkpoint**: Plan Terraform vérifié

### Étape 6: Déployer l'infrastructure

```bash
terraform apply -target=module.rg \
                -target=module.network \
                -target=module.acr \
                -target=module.mysql \
                -target=module.appservice
```

Tapez `yes` pour confirmer.

**Temps d'attente**: 10-15 minutes

**Checkpoint**: Infrastructure déployée

### Étape 7: Récupérer les outputs

```bash
terraform output
terraform output webapp_url
```

**Checkpoint**: URL de l'application récupérée

### Étape 8: Vérification du déploiement

```bash
# Obtenir l'URL
WEBAPP_URL=$(terraform output -raw webapp_url)

# Tester l'accès
curl -I $WEBAPP_URL

# Ouvrir dans le navigateur
xdg-open $WEBAPP_URL  # Linux
open $WEBAPP_URL      # macOS
```

**Checkpoint**: Application accessible

### Étape 9: Exécuter les migrations

```bash
WEBAPP_NAME="tc-dev-web-frc-01"
RESOURCE_GROUP="rg-nan_1"

# SSH vers la Web App
az webapp ssh --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP

# Dans le conteneur
cd /var/www/html
php artisan migrate --force
exit
```

**Checkpoint**: Migrations exécutées

### Étape 10: Vérification finale

```bash
# Consulter les logs
az webapp log tail --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP

# Vérifier l'état
az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --query state
```

**Résultat attendu**: State = "Running"

## Mise à jour de l'application

### Mise à jour du code

```bash
# 1. Modifier le code
cd sample-app-master/

# 2. Rebuild et push
az acr login --name tcdevacrfrc01
docker build -t tcdevacrfrc01.azurecr.io/sample-app:latest .
docker push tcdevacrfrc01.azurecr.io/sample-app:latest

# 3. Redémarrer la Web App
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1

# 4. Vérifier
curl https://tc-dev-web-frc-01.azurewebsites.net
```

## Monitoring

### Consulter les logs

```bash
# Logs en temps réel
az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Logs Docker
az webapp log tail --name tc-dev-web-frc-01 \
                   --resource-group rg-nan_1 \
                   --provider docker
```

### Vérifier l'état

```bash
az webapp show --name tc-dev-web-frc-01 \
               --resource-group rg-nan_1 \
               --query state
```

## Scaling

### Scaling vertical (changement de SKU)

```bash
# Passer à B2
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --sku B2
```

### Scaling horizontal

```bash
# Scaler à 3 instances
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --number-of-workers 3
```

## Rollback

### Retour à une version précédente

```bash
# Changer le tag Docker
az webapp config container set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --docker-custom-image-name tcdevacrfrc01.azurecr.io/sample-app:<ancien-tag>

# Redémarrer
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

## Checklist de déploiement

- [ ] Azure CLI configuré et connecté
- [ ] Terraform initialisé
- [ ] Variables configurées dans terraform.tfvars
- [ ] terraform plan exécuté et vérifié
- [ ] Infrastructure déployée avec terraform apply
- [ ] Image Docker construite et poussée vers ACR
- [ ] Web App accessible via l'URL
- [ ] Migrations de base de données exécutées
- [ ] Application fonctionne correctement
- [ ] Logs consultés pour vérifier l'absence d'erreurs

## Ressources créées

| Ressource | Nom | Description |
|-----------|-----|-------------|
| App Service Plan | tc-dev-asp-frc-01 | SKU B1 |
| Web App | tc-dev-web-frc-01 | Application Laravel |
| MySQL Server | tc-dev-mysql-frc-01 | Base de données |
| ACR | tcdevacrfrc01 | Registry Docker |
| VNet | tc-dev-vnet-frc-01 | Réseau virtuel |

## Références

- [Troubleshooting PaaS](../troubleshooting/paas-troubleshooting.md)
- [Architecture PaaS](../reference/architecture/architecture-paas.md)
- [Guide CI/CD](../operations/cicd-reference.md)

## Support

En cas de problème, consultez le [guide de troubleshooting PaaS](../troubleshooting/paas-troubleshooting.md).

