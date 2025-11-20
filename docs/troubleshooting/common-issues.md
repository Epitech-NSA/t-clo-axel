# Problèmes communs - Azure, Terraform, Docker

Ce guide résout les problèmes généraux qui affectent tous les types de déploiements.

## Table des matières

1. [Problèmes Azure](#problèmes-azure)
2. [Problèmes Terraform](#problèmes-terraform)
3. [Problèmes Docker](#problèmes-docker)
4. [Problèmes Réseau](#problèmes-réseau)
5. [Problèmes de coûts](#problèmes-de-coûts)

## Problèmes Azure

### Subscription non accessible

**Symptôme**: `Error: The subscription ... could not be found`

**Solution**:
```bash
# Lister les subscriptions disponibles
az account list --output table

# Définir la bonne subscription
az account set --subscription "6b9318b1-2215-418a-b0fd-ba0832e9b333"

# Vérifier
az account show
```

### Quota atteint

**Symptôme**: `Error: Quota exceeded for resource type`

**Solution**:
```bash
# Vérifier les quotas actuels
az vm list-usage --location francecentral --output table

# Demander une augmentation si nécessaire
# Portail Azure → Subscriptions → Usage + quotas
```

### Resource Provider non enregistré

**Symptôme**: `Error: The subscription is not registered to use namespace 'Microsoft.Compute'`

**Solution**:
```bash
# Enregistrer le provider
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ContainerRegistry

# Vérifier le statut (peut prendre quelques minutes)
az provider show --namespace Microsoft.Compute --query "registrationState"
```

### Policy Azure bloque la création

**Symptôme**: `Error: Resource creation blocked by Azure Policy`

**Solution**:
- Vérifier les policies appliquées sur la subscription
- Contacter l'administrateur Azure
- Utiliser une ressource alternative (ex: Public IPs au lieu de Load Balancer)

---

## Problèmes Terraform

### State lock bloqué

**Symptôme**: `Error: Error acquiring the state lock`

**Solution**:
```bash
cd terraform

# Option 1: Attendre 15 minutes
sleep 900

# Option 2: Force unlock (si certain qu'aucun autre terraform n'est en cours)
terraform force-unlock <LOCK_ID>
```

### State désynchronisé

**Symptôme**: `Error: Resource not found in state but exists in Azure`

**Solution**:
```bash
# Importer la ressource manquante
terraform import <resource_type>.<resource_name> <azure_resource_id>

# Exemple
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/rg-nan_1
```

### Plan Terraform trop long

**Symptôme**: `terraform plan` prend plus de 10 minutes

**Solution**:
```bash
# Utiliser -target pour limiter le scope
terraform plan -target=module.appservice

# Ou désactiver le refresh
terraform plan -refresh=false
```

### Provider Azure version incompatible

**Symptôme**: `Error: Unsupported provider version`

**Solution**:
```bash
# Mettre à jour le provider
cd terraform
rm -rf .terraform/
rm .terraform.lock.hcl
terraform init -upgrade
```

### Variable non définie

**Symptôme**: `Error: No value for required variable`

**Solution**:
```bash
# Vérifier terraform.tfvars
cd terraform
cat terraform.tfvars

# Ou utiliser -var
terraform plan -var="mysql_admin_password=MonMotDePasse"

# Ou variable d'environnement
export TF_VAR_mysql_admin_password="MonMotDePasse"
```

---

## Problèmes Docker

### Impossible de build l'image

**Symptôme**: `Error: Docker build failed`

**Solution**:
```bash
# Vérifier l'espace disque
df -h

# Nettoyer les images inutilisées
docker system prune -a

# Vérifier le Dockerfile
cd sample-app-master/
docker build --no-cache -t test:latest .
```

### Image trop volumineuse

**Symptôme**: L'image fait plus de 1GB

**Solution**:
```dockerfile
# Utiliser des images Alpine
FROM php:8.1-apache-alpine

# Nettoyer dans le Dockerfile
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Utiliser .dockerignore
echo "node_modules" >> .dockerignore
echo ".git" >> .dockerignore
```

### Push vers ACR échoue

**Symptôme**: `Error: denied: authentication required`

**Solution**:
```bash
# Re-login ACR
az acr login --name tcdevacrfrc01

# Vérifier les permissions
az acr repository list --name tcdevacrfrc01

# Si admin activé
az acr credential show --name tcdevacrfrc01
docker login tcdevacrfrc01.azurecr.io -u <username> -p <password>
```

### Container s'arrête immédiatement

**Symptôme**: `docker ps` ne montre pas le conteneur

**Solution**:
```bash
# Voir tous les conteneurs (y compris arrêtés)
docker ps -a

# Voir les logs
docker logs <container_id>

# Vérifier le CMD/ENTRYPOINT dans le Dockerfile
# Le processus principal doit rester en foreground
```

---

## Problèmes Réseau

### DNS ne résout pas

**Symptôme**: `Error: Could not resolve host`

**Solution**:
```bash
# Tester la résolution DNS
nslookup tc-dev-mysql-frc-01.mysql.database.azure.com

# Utiliser un DNS public
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Vérifier la connectivité réseau
ping 8.8.8.8
```

### Timeout de connexion

**Symptôme**: `Error: Connection timeout`

**Solution**:
```bash
# Vérifier les NSG (Network Security Groups)
az network nsg rule list --nsg-name <nsg-name> --resource-group rg-nan_1

# Vérifier les firewalls
# MySQL firewall
az mysql flexible-server firewall-rule list --name tc-dev-mysql-frc-01 --resource-group rg-nan_1

# Tester la connectivité
telnet <ip> <port>
nc -zv <ip> <port>
```

### SSL/TLS certificate invalid

**Symptôme**: `Error: SSL certificate problem`

**Solution**:
```bash
# Vérifier le certificat
openssl s_client -connect <domain>:443

# Pour tests uniquement: désactiver la vérification
curl -k https://...

# Mettre à jour les certificats CA
sudo apt update
sudo apt install --reinstall ca-certificates
```

---

## Problèmes de coûts

### Facture plus élevée que prévu

**Diagnostic**:
```bash
# Lister toutes les ressources
az resource list --resource-group rg-nan_1 --output table

# Vérifier les ressources actives
az vm list --output table
az webapp list --output table
az mysql flexible-server list --output table
```

**Solutions**:

#### 1. Arrêter les ressources en dev

```bash
# Arrêter MySQL (dev uniquement)
az mysql flexible-server stop --name tc-dev-mysql-frc-01 --resource-group rg-nan_1

# Arrêter les App Services (dev)
az webapp stop --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Scaler le VMSS à 0 (dev)
az vmss scale --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --new-capacity 0
```

#### 2. Supprimer les ressources inutilisées

```bash
# Détruire complètement l'environnement dev
cd terraform
terraform workspace select dev
terraform destroy
```

#### 3. Optimiser les SKUs

```bash
# Passer de B2 à B1
az appservice plan update --name tc-dev-asp-frc-01 --resource-group rg-nan_1 --sku B1

# Passer de Standard_B2s à Standard_B1s
az vmss update --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --vm-sku Standard_B1s
```

### Ressources fantômes

**Symptôme**: Facturé pour des ressources que vous ne voyez pas

**Solution**:
```bash
# Lister TOUTES les ressources dans la subscription
az resource list --output table

# Rechercher par tag
az resource list --tag project=TERRACLOUD --output table

# Supprimer une ressource spécifique
az resource delete --ids <resource-id>
```

---

## Problèmes de permissions

### Accès refusé à une ressource

**Symptôme**: `Error: (Forbidden) You do not have permission`

**Solution**:
```bash
# Vérifier vos rôles
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table

# Demander l'ajout du rôle nécessaire à l'admin
# Rôles communs: Contributor, Owner, Reader
```

### Identité managée ne fonctionne pas

**Symptôme**: `Error: Managed Identity authentication failed`

**Solution**:
```bash
# Vérifier que l'identité est activée
az webapp identity show --name tc-dev-web-frc-01 --resource-group rg-nan_1
az vmss identity show --name tc-dev-vmss-frc-01 --resource-group rg-nan_1

# Vérifier les role assignments
PRINCIPAL_ID=$(az webapp identity show --name tc-dev-web-frc-01 --resource-group rg-nan_1 --query principalId -o tsv)
az role assignment list --assignee $PRINCIPAL_ID --output table

# Attendre la propagation (peut prendre 2-5 minutes)
sleep 300
```

---

## Problèmes de performance

### Lenteur généralisée

**Diagnostic**:
```bash
# Vérifier les métriques
az monitor metrics list --resource <resource-id> --metric "Percentage CPU"

# Vérifier l'utilisation réseau
az monitor metrics list --resource <resource-id> --metric "Network In Total"
```

**Solutions**:
- Scaler verticalement (SKU supérieur)
- Scaler horizontalement (plus d'instances)
- Optimiser l'application (cache, requêtes DB)
- Changer de région (latence)

---

## Références

- [Troubleshooting PaaS](paas-troubleshooting.md)
- [Troubleshooting IaaS](iaas-troubleshooting.md)
- [Troubleshooting CI/CD](cicd-troubleshooting.md)
- [Troubleshooting Scripts](scripts-troubleshooting.md)
- [Documentation Azure](https://learn.microsoft.com/fr-fr/azure/)

## Support

Pour des problèmes spécifiques:
1. Consulter le guide de troubleshooting correspondant
2. Vérifier les logs détaillés
3. Consulter la documentation Azure
4. Ouvrir un ticket de support Azure

