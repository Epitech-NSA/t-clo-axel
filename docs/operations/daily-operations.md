# Opérations quotidiennes - TERRACLOUD

Guide des opérations courantes pour gérer et surveiller l'infrastructure au quotidien.

## Monitoring

### Consulter les logs

#### PaaS (App Service)

```bash
# Logs en temps réel
az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Logs Docker spécifiques
az webapp log tail --name tc-dev-web-frc-01 \
                   --resource-group rg-nan_1 \
                   --provider docker

# Via Makefile
make logs-paas ENV=dev
```

#### IaaS (VMSS)

```bash
# Via Ansible (tous les serveurs)
ansible all -i inventory/static.yml \
  -m shell -a "docker logs laravel-app --tail 50" \
  --become

# Via SSH (sur une VM spécifique)
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo docker logs laravel-app -f

# Via Makefile
make logs-iaas ENV=dev
```

### Vérifier l'état des ressources

```bash
# Statut général
make status ENV=dev

# Lister toutes les ressources
az resource list --resource-group rg-nan_1 --output table

# Vérifier une ressource spécifique
az webapp show --name tc-dev-web-frc-01 --resource-group rg-nan_1 --query state
az vmss list-instances --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --output table
```

### Métriques et performance

```bash
# CPU usage (PaaS)
az monitor metrics list \
  --resource "/subscriptions/.../sites/tc-dev-web-frc-01" \
  --metric "CpuTime"

# Nombre de requêtes
az monitor metrics list \
  --resource "/subscriptions/.../sites/tc-dev-web-frc-01" \
  --metric "Requests"

# CPU VMSS (IaaS)
az monitor metrics list \
  --resource $(az vmss show --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --query id -o tsv) \
  --metric "Percentage CPU"
```

## Accès SSH

### App Service (PaaS)

```bash
# SSH vers la Web App
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Via Makefile
make ssh-paas ENV=dev

# Commandes utiles dans le conteneur
cd /var/www/html
php artisan migrate
php artisan cache:clear
tail -f storage/logs/laravel.log
```

### VMSS (IaaS)

```bash
# SSH vers une instance
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Via Makefile
make ssh-iaas ENV=dev

# Commandes utiles dans la VM
sudo docker ps
sudo docker logs laravel-app
sudo docker exec -it laravel-app bash
sudo systemctl status docker
```

## Mise à jour de l'application

### Workflow standard

```bash
# 1. Modifier le code
nano sample-app-master/...

# 2. Build et push
make build-push ENV=dev

# 3. Redéployer
make dev-paas  # ou make dev-iaas

# 4. Vérifier
curl https://tc-dev-web-frc-01.azurewebsites.net
make test-paas ENV=dev
```

### Redémarrage rapide

#### PaaS
```bash
# Redémarrer l'App Service
az webapp restart --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Force le pull d'une nouvelle image
az webapp config container set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --docker-custom-image-name tcdevacrfrc01.azurecr.io/sample-app:latest
```

#### IaaS
```bash
# Redéployer l'application via Ansible
cd ansible
ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml

# Redémarrer le conteneur sur une VM spécifique
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo docker restart laravel-app
```

## Gestion de la base de données

### Exécuter les migrations

```bash
# PaaS
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1
php artisan migrate

# IaaS
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo docker exec laravel-app php artisan migrate
```

### Backup de la base de données

```bash
# Export manuel
mysqldump -h tc-dev-mysql-frc-01.mysql.database.azure.com \
          -u app_admin -p \
          app_database > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup via Azure
az mysql flexible-server backup create \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1
```

### Connexion directe à MySQL

```bash
# Depuis votre machine locale (si firewall configuré)
mysql -h tc-dev-mysql-frc-01.mysql.database.azure.com \
      -u app_admin -p

# Depuis la Web App ou une VM
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1
mysql -h tc-dev-mysql-frc-01.mysql.database.azure.com -u app_admin -p
```

## Scaling

### PaaS - Scaling vertical

```bash
# Passer de B1 à B2
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --sku B2

# Retour à B1
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --sku B1
```

### PaaS - Scaling horizontal

```bash
# Scaler à 3 instances (requiert SKU Standard+)
az appservice plan update --name tc-dev-asp-frc-01 \
                          --resource-group rg-nan_1 \
                          --number-of-workers 3
```

### IaaS - Scaling manuel

```bash
# Scaler à 3 instances
az vmss scale \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --new-capacity 3

# Attendre que les instances soient prêtes
az vmss list-instances \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Déployer l'application sur les nouvelles instances
cd ansible
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml
```

## Gestion des coûts

### Arrêter les ressources (dev uniquement)

```bash
# Arrêter MySQL
az mysql flexible-server stop --name tc-dev-mysql-frc-01 --resource-group rg-nan_1

# Arrêter App Service
az webapp stop --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Scaler VMSS à 0
az vmss scale --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --new-capacity 0
```

### Redémarrer les ressources

```bash
# Démarrer MySQL
az mysql flexible-server start --name tc-dev-mysql-frc-01 --resource-group rg-nan_1

# Démarrer App Service
az webapp start --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Scaler VMSS à 1
az vmss scale --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --new-capacity 1
```

### Consulter les coûts

```bash
# Via Azure Portal
# Cost Management + Billing → Cost analysis

# Lister les ressources actives
az resource list --resource-group rg-nan_1 --output table
```

## Health checks

### Test rapide

```bash
# PaaS
curl -I https://tc-dev-web-frc-01.azurewebsites.net

# IaaS
INSTANCE_IP=$(az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query "[0].ipAddress" -o tsv)
curl -I http://$INSTANCE_IP

# Via Makefile
make test-paas ENV=dev
make test-iaas ENV=dev
```

### Tests complets

```bash
# Tests automatisés
make test-paas ENV=dev
make test-iaas ENV=dev
make test-https
make test-db ENV=dev
```

## Afficher les URLs

```bash
# Via Makefile
make urls ENV=dev

# Manuellement
terraform output -raw webapp_url
terraform output -raw mysql_fqdn
terraform output -raw acr_login_server
```

## Nettoyage quotidien

### Nettoyer les images Docker locales

```bash
# Lister les images
docker images | grep sample-app

# Supprimer les anciennes images
docker rmi tcdevacrfrc01.azurecr.io/sample-app:old-tag

# Nettoyer tout
docker system prune -a
```

### Nettoyer les fichiers temporaires

```bash
make clean
```

## Checklist quotidienne

### Matin (environnement dev)

- [ ] Vérifier l'état des ressources: `make status ENV=dev`
- [ ] Consulter les logs: `make logs-paas ENV=dev`
- [ ] Vérifier les coûts dans Azure Portal
- [ ] Tester l'application: `make test-paas ENV=dev`

### Soir (environnement dev)

- [ ] Arrêter les ressources si non utilisées
- [ ] Vérifier qu'aucune erreur n'est dans les logs
- [ ] Commit et push les changements du jour

### Hebdomadaire

- [ ] Vérifier les mises à jour disponibles (Terraform, Ansible, etc.)
- [ ] Backup de la base de données
- [ ] Revue des coûts
- [ ] Nettoyage des anciennes images Docker dans ACR

## Références

- [Scripts Reference](scripts-reference.md)
- [CI/CD Reference](cicd-reference.md)
- [Configuration avancée](advanced-configuration.md)
- [Troubleshooting](../troubleshooting/README.md)

## Support

Pour des opérations plus avancées, consultez la [configuration avancée](advanced-configuration.md).

