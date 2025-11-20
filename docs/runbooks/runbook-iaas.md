# Runbook: Déploiement IaaS - VM Scale Set

## Objectif

Déployer l'application Laravel sur VM Scale Set avec automatisation Ansible.

**Durée estimée**: 30-35 minutes

## Prérequis

### Outils requis

- Azure CLI 2.40+
- Terraform 1.0+
- Ansible 2.9+
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
ansible --version
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

### Étape 2: Générer les clés SSH

```bash
# Générer la paire de clés
ssh-keygen -t ed25519 -f ~/.ssh/terracloud-dev-key -C "terracloud-dev-vmss"

# Afficher la clé publique
cat ~/.ssh/terracloud-dev-key.pub

# Vérifier les permissions
chmod 600 ~/.ssh/terracloud-dev-key
chmod 644 ~/.ssh/terracloud-dev-key.pub
```

**Checkpoint**: Clés SSH générées

### Étape 3: Build et push de l'image Docker

```bash
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

### Étape 4: Configuration Terraform

```bash
cd terraform

# Créer le workspace
terraform workspace new dev  # ou prod
terraform workspace select dev

# Configurer les variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Variables requises:

```hcl
mysql_admin_password  = "VotreMotDePasseSecurise123!"
ssh_public_key_iaas   = "ssh-ed25519 AAAAC3Nza... votre-email@exemple.com"
environment = "dev"
location    = "francecentral"
```

**Checkpoint**: Variables configurées

### Étape 5: Initialisation Terraform

```bash
terraform init
terraform validate
```

**Checkpoint**: Terraform initialisé

### Étape 6: Planifier le déploiement

```bash
# Vérifier le workspace
terraform workspace show

# Plan l'infrastructure IaaS
terraform plan -target=module.vmss \
               -target=azurerm_role_assignment.vmss_acr_pull \
               -target=azurerm_mysql_flexible_server_firewall_rule.vmss_to_mysql
```

**Checkpoint**: Plan Terraform vérifié

### Étape 7: Déployer l'infrastructure

```bash
terraform apply -target=module.vmss \
                -target=azurerm_role_assignment.vmss_acr_pull \
                -target=azurerm_mysql_flexible_server_firewall_rule.vmss_to_mysql
```

Tapez `yes` pour confirmer.

**Temps d'attente**: 10-15 minutes

**Checkpoint**: Infrastructure déployée

### Étape 8: Récupérer les IPs publiques

```bash
# Lister les IPs
az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Récupérer l'IP de la première instance
INSTANCE_IP=$(az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query "[0].ipAddress" -o tsv)

echo "Instance IP: $INSTANCE_IP"
```

**Checkpoint**: IPs publiques récupérées

### Étape 9: Attendre l'initialisation (cloud-init)

```bash
# Vérifier le statut des instances
az vmss list-instances \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Attendre 2-3 minutes pour cloud-init
sleep 180
```

**Checkpoint**: Instances démarrées

### Étape 10: Configurer Ansible

```bash
cd ../ansible

# Créer l'inventaire statique
VMSS_IP=$(az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query "[0].ipAddress" -o tsv)

cat > inventory/static.yml << EOF
---
all:
  children:
    vmss_instances:
      hosts:
        vmss-instance-1:
          ansible_host: $VMSS_IP
          ansible_user: azureuser
          ansible_ssh_private_key_file: ~/.ssh/terracloud-dev-key
      vars:
        acr_name: "tcdevacrfrc01"
        acr_login_server: "tcdevacrfrc01.azurecr.io"
        docker_image_full: "tcdevacrfrc01.azurecr.io/sample-app:latest"
        app_container_name: "laravel-app"
        app_port: 80
        mysql_host: "tc-dev-mysql-frc-01.mysql.database.azure.com"
        mysql_port: "3306"
        mysql_database: "app_database"
        mysql_username: "app_admin"
        mysql_password: "VotreMotDePasseMySQL"
        laravel_app_key: "base64:DJYTvaRkEZ/YcQsX3TMpB0iCjgme2rhlIOus9A1hnj4="
        laravel_app_env: "dev"
        laravel_app_debug: "true"
EOF

# Tester la connectivité
ansible all -i inventory/static.yml -m ping
```

**Checkpoint**: Ansible peut se connecter aux VMs

### Étape 11: Installer Docker

```bash
# Exécuter le playbook Docker
ansible-playbook -i inventory/static.yml playbooks/docker-only.yml

# Vérifier l'installation
ansible all -i inventory/static.yml -m shell -a "docker --version" --become
```

**Checkpoint**: Docker installé sur toutes les VMs

### Étape 12: Déployer l'application

```bash
# Déployer l'application
ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml
```

Le playbook effectue:
- Connexion à ACR via identité managée
- Pull de l'image Docker
- Démarrage du conteneur avec variables d'environnement
- Exécution des migrations Laravel
- Vérification de santé

**Temps d'attente**: 5-10 minutes

**Checkpoint**: Application déployée

### Étape 13: Vérification du déploiement

```bash
# Tester l'accès
curl http://$INSTANCE_IP

# Test avec détails
curl -v http://$INSTANCE_IP

# Vérifier la page Laravel
curl -s http://$INSTANCE_IP | grep -o "Laravel"

# Ouvrir dans le navigateur
xdg-open http://$INSTANCE_IP  # Linux
open http://$INSTANCE_IP      # macOS
```

**Checkpoint**: Application accessible et fonctionnelle

## Configuration HTTPS (optionnel)

### Option 1: Nginx + Let's Encrypt (recommandé pour dev)

```bash
# Configurer le domaine (exemple avec nip.io)
VMSS_IP_FORMATTED=$(echo $INSTANCE_IP | tr '.' '-')
DOMAIN="${VMSS_IP_FORMATTED}.nip.io"

# Exécuter le playbook HTTPS
export DOMAIN=$DOMAIN
ansible-playbook -i inventory/static.yml playbooks/setup-https.yml

# Tester HTTPS
curl https://$DOMAIN
```

## Mise à jour de l'application

```bash
# 1. Modifier le code
cd sample-app-master/

# 2. Rebuild et push
az acr login --name tcdevacrfrc01
docker build -t tcdevacrfrc01.azurecr.io/sample-app:latest .
docker push tcdevacrfrc01.azurecr.io/sample-app:latest

# 3. Redéployer avec Ansible
cd ../ansible
ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml

# 4. Vérifier
curl http://$INSTANCE_IP
```

## Monitoring

### Consulter les logs

```bash
# Via Ansible
ansible all -i inventory/static.yml \
  -m shell -a "docker logs laravel-app --tail 50" \
  --become

# Via SSH
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo docker logs laravel-app -f
```

### Vérifier l'état des conteneurs

```bash
# Via Ansible
ansible all -i inventory/static.yml \
  -m shell -a "docker ps" \
  --become
```

### Accès SSH direct

```bash
# SSH vers l'instance
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Commandes utiles dans la VM
sudo docker ps
sudo docker logs laravel-app
sudo systemctl status docker
```

## Scaling

### Scaling manuel

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

## Rollback

```bash
# Redéployer une ancienne version
cd ansible
ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml \
  -e "docker_image_full=tcdevacrfrc01.azurecr.io/sample-app:<ancien-tag>"
```

## Checklist de déploiement

- [ ] Prérequis installés (Azure CLI, Terraform, Ansible, Docker)
- [ ] Clé SSH générée
- [ ] Connexion Azure établie
- [ ] Image Docker construite et poussée vers ACR
- [ ] Variables Terraform configurées
- [ ] Infrastructure Terraform déployée
- [ ] IPs publiques des instances VMSS récupérées
- [ ] Instances VMSS démarrées et accessibles
- [ ] Docker installé via Ansible
- [ ] Application déployée via Ansible
- [ ] Application accessible via les IPs publiques
- [ ] Auto-scaling configuré et testé

## Ressources créées

| Ressource | Nom | Description |
|-----------|-----|-------------|
| VM Scale Set | tc-dev-vmss-frc-01 | 1-2 instances B2s |
| Public IPs | Dynamiques | Une par instance |
| MySQL Server | tc-dev-mysql-frc-01 | Base de données |
| ACR | tcdevacrfrc01 | Registry Docker |
| VNet | tc-dev-vnet-frc-01 | Réseau virtuel |
| NSG | nsg-vmss | Règles de sécurité |

## Références

- [Troubleshooting IaaS](../troubleshooting/iaas-troubleshooting.md)
- [Architecture IaaS](../reference/architecture/architecture-iaas.md)
- [Guide CI/CD](../operations/cicd-reference.md)

## Support

En cas de problème, consultez le [guide de troubleshooting IaaS](../troubleshooting/iaas-troubleshooting.md).

