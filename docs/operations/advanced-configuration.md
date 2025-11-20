# Configuration avancée - TERRACLOUD

Guide des configurations avancées et des optimisations possibles.

## Auto-scaling avancé

### PaaS - Configuration auto-scaling

```bash
# Créer une règle d'auto-scaling basée sur le CPU (requiert Standard+)
az monitor autoscale create \
  --resource-group rg-nan_1 \
  --resource /subscriptions/.../serverfarms/tc-dev-asp-frc-01 \
  --name autoscale-webapp \
  --min-count 1 \
  --max-count 5 \
  --count 2

# Règle: scale out si CPU > 75%
az monitor autoscale rule create \
  --resource-group rg-nan_1 \
  --autoscale-name autoscale-webapp \
  --condition "Percentage CPU > 75 avg 5m" \
  --scale out 1

# Règle: scale in si CPU < 25%
az monitor autoscale rule create \
  --resource-group rg-nan_1 \
  --autoscale-name autoscale-webapp \
  --condition "Percentage CPU < 25 avg 5m" \
  --scale in 1
```

### IaaS - Modifier les seuils auto-scaling

Via Terraform (`terraform/iaas.tf`):

```hcl
resource "azurerm_monitor_autoscale_setting" "vmss" {
  profile {
    capacity {
      default = 2
      minimum = 1
      maximum = 10  # Modifier selon besoin
    }
    
    rule {
      scale_action {
        cooldown = "PT3M"  # 3 minutes au lieu de 5
      }
    }
  }
}
```

## Intégration VNet

### PaaS - Activer l'intégration VNet

```bash
# Requiert Standard+ tier
az webapp vnet-integration add \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --vnet tc-dev-vnet-frc-01 \
  --subnet subnet-web
```

### IaaS - Configuration réseau avancée

Modifier les NSG rules dans `terraform/modules/network/`:

```hcl
# Ajouter une règle personnalisée
resource "azurerm_network_security_rule" "custom" {
  name                        = "Allow-Custom"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name        = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}
```

## Domaine personnalisé et SSL

### PaaS - Ajouter un domaine personnalisé

```bash
# Ajouter le domaine
az webapp config hostname add \
  --webapp-name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --hostname www.mondomaine.com

# Créer un certificat managé (gratuit)
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

### IaaS - Configuration HTTPS avec Let's Encrypt

Déjà implémenté via Ansible (`playbooks/setup-https.yml`):

```bash
# Avec un vrai domaine
export DOMAIN="app.mondomaine.com"
ansible-playbook -i inventory/static.yml playbooks/setup-https.yml

# Avec nip.io pour tests
VMSS_IP_FORMATTED=$(echo $INSTANCE_IP | tr '.' '-')
export DOMAIN="${VMSS_IP_FORMATTED}.nip.io"
ansible-playbook -i inventory/static.yml playbooks/setup-https.yml
```

## Slots de déploiement (PaaS uniquement)

```bash
# Créer un slot de staging (requiert Standard+)
az webapp deployment slot create \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --slot staging

# Déployer sur staging
az webapp config container set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --slot staging \
  --docker-custom-image-name tcdevacrfrc01.azurecr.io/sample-app:staging

# Swap staging → production
az webapp deployment slot swap \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --slot staging
```

## Backup automatique

### Backup de la base de données

```bash
# Créer un plan de backup
az mysql flexible-server backup create \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1

# Lister les backups
az mysql flexible-server backup list \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1
```

### Script de backup automatique

Créer un script `backup.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Backup MySQL
mysqldump -h tc-dev-mysql-frc-01.mysql.database.azure.com \
          -u app_admin -p$MYSQL_PASSWORD \
          app_database > $BACKUP_DIR/backup_$DATE.sql

# Upload vers Azure Storage (optionnel)
az storage blob upload \
  --account-name <storage-account> \
  --container-name backups \
  --name backup_$DATE.sql \
  --file $BACKUP_DIR/backup_$DATE.sql
```

## Monitoring avancé

### Azure Application Insights (PaaS)

```bash
# Activer Application Insights
az monitor app-insights component create \
  --app tc-dev-insights \
  --location francecentral \
  --resource-group rg-nan_1

# Lier à l'App Service
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app tc-dev-insights \
  --resource-group rg-nan_1 \
  --query instrumentationKey -o tsv)

az webapp config appsettings set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
```

### Alertes personnalisées

```bash
# Alerte CPU élevé
az monitor metrics alert create \
  --name high-cpu-alert \
  --resource-group rg-nan_1 \
  --scopes /subscriptions/.../sites/tc-dev-web-frc-01 \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action email your-email@example.com

# Alerte erreurs HTTP 500
az monitor metrics alert create \
  --name http-500-alert \
  --resource-group rg-nan_1 \
  --scopes /subscriptions/.../sites/tc-dev-web-frc-01 \
  --condition "total Http5xx > 10" \
  --window-size 5m
```

## Optimisation des coûts

### Réservations Azure

Pour un usage long terme (1-3 ans):

```bash
# Consulter les options de réservation
# Azure Portal → Reservations → Purchase
```

### Politique de shutdown automatique (dev)

Script `shutdown-dev.sh`:

```bash
#!/bin/bash
# Arrêter les ressources dev en soirée

# Arrêter App Service
az webapp stop --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Scaler VMSS à 0
az vmss scale --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --new-capacity 0

# Arrêter MySQL
az mysql flexible-server stop --name tc-dev-mysql-frc-01 --resource-group rg-nan_1
```

Configurer avec cron (sur votre machine ou dans Azure Automation):

```bash
# Arrêt à 19h00
0 19 * * * /path/to/shutdown-dev.sh

# Démarrage à 08h00
0 8 * * * /path/to/startup-dev.sh
```

## Sécurité avancée

### Activer le firewall Web Application (PaaS)

```bash
# Requiert une App Service Plan Standard+
# Configurer via Azure Portal → Networking → Access restrictions
```

### Verrouillage réseau (IaaS)

Modifier les NSG pour limiter l'accès SSH:

```bash
# Limiter SSH à une IP spécifique
az network nsg rule update \
  --resource-group rg-nan_1 \
  --nsg-name nsg-vmss \
  --name Allow-SSH-Inbound \
  --source-address-prefixes "123.456.789.0/24"
```

### Rotation automatique des secrets

Utiliser Azure Key Vault:

```bash
# Créer un Key Vault
az keyvault create \
  --name tc-dev-kv \
  --resource-group rg-nan_1 \
  --location francecentral

# Stocker un secret
az keyvault secret set \
  --vault-name tc-dev-kv \
  --name mysql-password \
  --value "VotreMotDePasse"

# Donner accès à l'App Service
az webapp identity assign --name tc-dev-web-frc-01 --resource-group rg-nan_1
PRINCIPAL_ID=$(az webapp identity show --name tc-dev-web-frc-01 --resource-group rg-nan_1 --query principalId -o tsv)
az keyvault set-policy --name tc-dev-kv --object-id $PRINCIPAL_ID --secret-permissions get
```

## Performance tuning

### Cache Laravel

```bash
# SSH vers l'application
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Dans le conteneur
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```

### Index MySQL

Créer des index pour optimiser les requêtes fréquentes.

### CDN pour les assets statiques

```bash
# Créer un CDN endpoint
az cdn endpoint create \
  --resource-group rg-nan_1 \
  --profile-name tc-cdn-profile \
  --name tc-cdn-endpoint \
  --origin tc-dev-web-frc-01.azurewebsites.net
```

## Références

- [Opérations quotidiennes](daily-operations.md)
- [Scripts Reference](scripts-reference.md)
- [CI/CD Reference](cicd-reference.md)
- [Documentation Azure](https://learn.microsoft.com/fr-fr/azure/)

## Support

Pour toute question sur les configurations avancées, consultez la documentation Azure ou ouvrez une issue.

