# Troubleshooting PaaS - Azure App Service

Ce guide résout les problèmes courants lors du déploiement PaaS avec Azure App Service.

## Table des matières

1. [L'application ne démarre pas](#lapplication-ne-démarre-pas)
2. [Impossible de pull l'image depuis ACR](#impossible-de-pull-limage-depuis-acr)
3. [Erreur de connexion à MySQL](#erreur-de-connexion-à-mysql)
4. [Terraform state lock](#terraform-state-lock)
5. [Performance lente](#performance-lente)
6. [Certificat SSL invalide](#certificat-ssl-invalide)

## L'application ne démarre pas

### Symptôme

```bash
curl https://tc-dev-web-frc-01.azurewebsites.net
# Timeout ou 503 Service Unavailable
```

### Diagnostic

```bash
# Vérifier les logs Docker
az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Vérifier la configuration
az webapp config show --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Vérifier l'état de l'app
az webapp show --name tc-dev-web-frc-01 --resource-group rg-nan_1 --query state
```

### Solutions

#### Solution 1: Image Docker incorrecte

```bash
# Vérifier l'image dans ACR
az acr repository show-tags --name tcdevacrfrc01 --repository sample-app

# Reconstruire et pousser
cd sample-app-master/
docker build -t tcdevacrfrc01.azurecr.io/sample-app:latest .
docker push tcdevacrfrc01.azurecr.io/sample-app:latest

# Redémarrer la Web App
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

#### Solution 2: Variables d'environnement manquantes

```bash
# Lister les variables
az webapp config appsettings list --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Ajouter une variable manquante
az webapp config appsettings set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --settings "DB_PASSWORD=MonMotDePasse"
```

#### Solution 3: Port incorrect

```bash
# Le conteneur doit écouter sur le port défini par WEBSITES_PORT
az webapp config appsettings set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --settings "WEBSITES_PORT=80"
```

#### Solution 4: Conteneur crashe au démarrage

```bash
# Consulter les logs détaillés
az webapp log download --name tc-dev-web-frc-01 \
                       --resource-group rg-nan_1 \
                       --log-file app-logs.zip

unzip app-logs.zip
cat LogFiles/*/docker.log

# Vérifier les dépendances PHP manquantes
# Vérifier les permissions de fichiers
# Vérifier la configuration Laravel (.env)
```

---

## Impossible de pull l'image depuis ACR

### Symptôme

```
Error: Failed to pull image from registry
```

### Diagnostic

```bash
# Vérifier que l'identité managée existe
az webapp identity show --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Vérifier le rôle ACR
az role assignment list --assignee $(az webapp identity show --name tc-dev-web-frc-01 --resource-group rg-nan_1 --query principalId -o tsv)
```

### Solutions

#### Solution 1: Réassigner le rôle ACR

```bash
# Récupérer le Principal ID
PRINCIPAL_ID=$(az webapp identity show --name tc-dev-web-frc-01 --resource-group rg-nan_1 --query principalId -o tsv)

# Récupérer l'ID de l'ACR
ACR_ID=$(az acr show --name tcdevacrfrc01 --query id -o tsv)

# Réassigner le rôle
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID

# Attendre quelques minutes pour la propagation
sleep 60

# Redémarrer la Web App
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

#### Solution 2: Utiliser Admin credentials (temporaire)

```bash
# Activer l'admin user sur ACR (à éviter en production)
az acr update --name tcdevacrfrc01 --admin-enabled true

# Récupérer les credentials
az acr credential show --name tcdevacrfrc01

# Configurer la Web App avec les credentials
az webapp config container set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --docker-custom-image-name tcdevacrfrc01.azurecr.io/sample-app:latest \
  --docker-registry-server-url https://tcdevacrfrc01.azurecr.io \
  --docker-registry-server-user tcdevacrfrc01 \
  --docker-registry-server-password <password-from-previous-command>
```

---

## Erreur de connexion à MySQL

### Symptôme

```
SQLSTATE[HY000] [2002] Connection refused
```

### Diagnostic

```bash
# Vérifier les règles de firewall MySQL
az mysql flexible-server firewall-rule list \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1

# Vérifier les variables de connexion DB
az webapp config appsettings list \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --query "[?contains(name, 'DB_')]"
```

### Solutions

#### Solution 1: Ajouter la règle firewall pour Azure Services

```bash
az mysql flexible-server firewall-rule create \
  --name AllowAzureServices \
  --resource-group rg-nan_1 \
  --server-name tc-dev-mysql-frc-01 \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

#### Solution 2: Vérifier les variables d'environnement

```bash
# Lister les variables DB
az webapp config appsettings list \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --query "[?contains(name, 'DB_')]" \
  --output table

# Corriger si nécessaire
az webapp config appsettings set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --settings \
    "DB_HOST=tc-dev-mysql-frc-01.mysql.database.azure.com" \
    "DB_DATABASE=app_database" \
    "DB_USERNAME=app_admin" \
    "DB_PASSWORD=VotreMotDePasse"
```

#### Solution 3: Tester la connexion depuis la Web App

```bash
# SSH vers la Web App
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Dans le conteneur
mysql -h tc-dev-mysql-frc-01.mysql.database.azure.com -u app_admin -p
# Entrer le mot de passe
```

#### Solution 4: Vérifier que MySQL est démarré

```bash
# Vérifier l'état du serveur MySQL
az mysql flexible-server show \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1 \
  --query "state" -o tsv

# Si "Stopped", démarrer le serveur
az mysql flexible-server start \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1
```

---

## Terraform state lock

### Symptôme

```
Error: Error acquiring the state lock
```

### Diagnostic

```bash
# Le message d'erreur contient le Lock ID
# Exemple: Lock ID: abc123-456def-789ghi
```

### Solutions

#### Solution 1: Attendre la fin de l'opération précédente

Si un autre déploiement est en cours, attendre qu'il se termine (5-10 minutes).

#### Solution 2: Forcer le déblocage

**⚠️ ATTENTION**: À utiliser uniquement si vous êtes certain qu'aucun autre terraform n'est en cours.

```bash
cd terraform

# Identifier le LOCK_ID dans le message d'erreur
terraform force-unlock <LOCK_ID>
```

#### Solution 3: Vérifier le backend

```bash
# Si backend Azure Storage
az storage blob list \
  --account-name sttcdevfrc01 \
  --container-name tfstate \
  --output table

# Supprimer manuellement le lock (dernier recours)
az storage blob delete \
  --account-name sttcdevfrc01 \
  --container-name tfstate \
  --name terraform.tfstate.lock
```

---

## Performance lente

### Symptôme

L'application répond lentement (>2 secondes pour une page simple).

### Diagnostic

```bash
# Vérifier les métriques CPU
az monitor metrics list \
  --resource "/subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333/resourceGroups/rg-nan_1/providers/Microsoft.Web/sites/tc-dev-web-frc-01" \
  --metric "CpuTime" \
  --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')

# Vérifier la mémoire
az monitor metrics list \
  --resource "/subscriptions/6b9318b1-2215-418a-b0fd-ba0832e9b333/resourceGroups/rg-nan_1/providers/Microsoft.Web/sites/tc-dev-web-frc-01" \
  --metric "MemoryWorkingSet"

# Consulter les logs pour identifier les requêtes lentes
az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

### Solutions

#### Solution 1: Scaler verticalement

```bash
# Passer de B1 à B2
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --sku B2
```

#### Solution 2: Activer le cache Laravel

```bash
# SSH vers la Web App
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Dans le conteneur
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

#### Solution 3: Optimiser MySQL

```bash
# Ajouter des index si nécessaire
# Vérifier les requêtes lentes dans Laravel logs
# Considérer un upgrade du SKU MySQL
```

---

## Certificat SSL invalide

### Symptôme

Le certificat SSL n'est pas valide ou a expiré.

### Diagnostic

```bash
# Vérifier le certificat
az webapp config ssl list \
  --resource-group rg-nan_1 \
  --output table

# Tester via OpenSSL
openssl s_client -connect tc-dev-web-frc-01.azurewebsites.net:443 -servername tc-dev-web-frc-01.azurewebsites.net
```

### Solutions

#### Solution 1: Utiliser le certificat managé Azure

```bash
# Pour azurewebsites.net, le certificat est automatique et géré par Azure
# Redémarrer la Web App
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

#### Solution 2: Domaine personnalisé

Si vous utilisez un domaine personnalisé:

```bash
# Créer un certificat managé
az webapp config ssl create \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --hostname www.mondomaine.com

# Lier le certificat
az webapp config ssl bind \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

---

## Problèmes courants supplémentaires

### Web App ne démarre pas après redéploiement

**Solution**: Attendre 2-3 minutes pour le pull de l'image et le démarrage du conteneur.

```bash
# Suivre les logs en temps réel
az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1
```

### Erreur 500 Internal Server Error

**Diagnostic**:
1. Consulter les logs Laravel
2. Vérifier la configuration `.env`
3. Vérifier les permissions de fichiers

```bash
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Dans le conteneur
tail -f storage/logs/laravel.log
```

### L'App Service Plan coûte trop cher

**Solutions**:
- Passer à un SKU inférieur (B1 → F1 gratuit pour tests)
- Configurer des horaires d'arrêt automatique (dev)
- Partager l'App Service Plan entre plusieurs Web Apps

```bash
# Passer au Free tier (F1) - limité
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --sku F1
```

---

## Références

- [Runbook PaaS](../runbooks/runbook-paas.md)
- [Architecture PaaS](../reference/architecture/architecture-paas.md)
- [Problèmes communs](common-issues.md)
- [Documentation Azure App Service](https://learn.microsoft.com/fr-fr/azure/app-service/)

## Support

Pour des problèmes non couverts ici:
1. Consulter les [problèmes communs](common-issues.md)
2. Vérifier la [documentation Azure](https://learn.microsoft.com/fr-fr/azure/app-service/troubleshoot-diagnostic-logs)
3. Consulter les logs détaillés de l'application

