# Troubleshooting IaaS - VM Scale Set

Ce guide résout les problèmes courants lors du déploiement IaaS avec VM Scale Set et Ansible.

## Table des matières

1. [Les VMs ne sont pas accessibles via SSH](#les-vms-ne-sont-pas-accessibles-via-ssh)
2. [Docker n'est pas installé sur les VMs](#docker-nest-pas-installé-sur-les-vms)
3. [Impossible de pull l'image depuis ACR](#impossible-de-pull-limage-depuis-acr)
4. [L'application ne répond pas via l'IP publique](#lapplication-ne-répond-pas-via-lip-publique)
5. [Erreur de connexion MySQL](#erreur-de-connexion-mysql)
6. [L'auto-scaling ne fonctionne pas](#lauto-scaling-ne-fonctionne-pas)
7. [Inventaire Ansible ne fonctionne pas](#inventaire-ansible-ne-fonctionne-pas)
8. [NSG bloque le trafic](#nsg-bloque-le-trafic)

## Les VMs ne sont pas accessibles via SSH

### Symptôme

```bash
ansible all -i inventory/azure_rm.yml -m ping
# Connection timeout

# ou
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
# Connection refused
```

### Diagnostic

```bash
# Vérifier que les VMs sont en cours d'exécution
az vmss list-instances \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Vérifier les NSG rules
az network nsg rule list \
  --nsg-name nsg-vmss \
  --resource-group rg-nan_1 \
  --output table

# Tester la connectivité directe
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP -v
```

### Solutions

#### Solution 1: Attendre l'initialisation cloud-init

Les VMs prennent 2-3 minutes après création pour être accessibles.

```bash
# Attendre
sleep 180

# Vérifier le statut
az vmss list-instances \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query "[].{Name:name, State:provisioningState}" \
  --output table

# Retry
ansible all -i inventory/static.yml -m ping
```

#### Solution 2: Vérifier la clé SSH

```bash
# Vérifier que la bonne clé est utilisée
ssh-add -l

# Vérifier les permissions
chmod 600 ~/.ssh/terracloud-dev-key
chmod 644 ~/.ssh/terracloud-dev-key.pub

# Vérifier le contenu de la clé publique
cat ~/.ssh/terracloud-dev-key.pub
# Doit commencer par: ssh-ed25519 AAAAC3...

# Comparer avec la clé dans Terraform
terraform output vmss_ssh_key
```

#### Solution 3: Vérifier le NSG

```bash
# S'assurer que le port 22 est ouvert
az network nsg rule show \
  --nsg-name nsg-vmss \
  --resource-group rg-nan_1 \
  --name Allow-SSH-Inbound

# Si la règle n'existe pas, la créer
az network nsg rule create \
  --resource-group rg-nan_1 \
  --nsg-name nsg-vmss \
  --name Allow-SSH-Inbound \
  --priority 100 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow
```

#### Solution 4: Vérifier les IPs publiques

```bash
# Lister toutes les IPs publiques des instances
az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Tester chaque IP
for ip in $(az vmss list-instance-public-ips --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --query "[].ipAddress" -o tsv); do
  echo "Testing $ip"
  ssh -i ~/.ssh/terracloud-dev-key azureuser@$ip -o ConnectTimeout=5 echo "OK" || echo "FAIL"
done
```

---

## Docker n'est pas installé sur les VMs

### Symptôme

```bash
ansible all -i inventory/static.yml -m shell -a "docker --version"
# docker: command not found
```

### Diagnostic

```bash
# Vérifier si cloud-init a terminé
ansible all -i inventory/static.yml -m shell -a "cloud-init status" -b

# Vérifier les logs cloud-init
ansible all -i inventory/static.yml -m shell -a "cat /var/log/cloud-init.log" -b
```

### Solutions

#### Solution 1: Réexécuter le playbook Docker

```bash
cd ansible

# Réexécuter l'installation Docker
ansible-playbook -i inventory/static.yml playbooks/docker-only.yml

# Vérifier
ansible all -i inventory/static.yml -m shell -a "docker --version" -b
```

#### Solution 2: Installation manuelle

Si Ansible échoue, installer manuellement:

```bash
# SSH vers la VM
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Installer Docker
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker azureuser

# Tester
docker --version

# Logout et login pour appliquer le groupe
exit
```

#### Solution 3: Vérifier les dépôts apt

```bash
# SSH vers la VM
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Vérifier la connexion internet
ping -c 3 8.8.8.8

# Vérifier les dépôts
sudo apt update
sudo apt-cache policy docker.io

# Si pas de réponse, vérifier le NSG outbound
```

---

## Impossible de pull l'image depuis ACR

### Symptôme

```
Error: Failed to pull image from ACR
```

### Diagnostic

```bash
# Vérifier l'identité managée du VMSS
az vmss identity show \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1

# Vérifier le role assignment
VMSS_PRINCIPAL=$(az vmss identity show \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query principalId -o tsv)

az role assignment list --assignee $VMSS_PRINCIPAL --output table
```

### Solutions

#### Solution 1: Vérifier et recréer le role assignment

```bash
# Depuis le dossier terraform
cd terraform

# Recréer le role assignment
terraform apply -target=azurerm_role_assignment.vmss_acr_pull

# Attendre la propagation (2-3 minutes)
sleep 180
```

#### Solution 2: Test manuel depuis la VM

```bash
# SSH dans une VM
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Se connecter à Azure avec l'identité managée
az login --identity

# Tester la connexion ACR
az acr login --name tcdevacrfrc01

# Pull manuel de l'image
sudo docker pull tcdevacrfrc01.azurecr.io/sample-app:latest

# Si cela fonctionne, le problème vient du playbook Ansible
```

#### Solution 3: Vérifier la configuration réseau

```bash
# Vérifier que la VM peut accéder à ACR
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Tester la résolution DNS
nslookup tcdevacrfrc01.azurecr.io

# Tester la connectivité
curl -I https://tcdevacrfrc01.azurecr.io/v2/

# Résultat attendu: 401 Unauthorized (normal sans auth)
```

---

## L'application ne répond pas via l'IP publique

### Symptôme

```bash
curl http://$INSTANCE_IP
# Connection timeout
```

### Diagnostic

```bash
# Vérifier le statut de l'instance
az vmss list-instances \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Vérifier les IPs publiques assignées
az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1

# SSH et tester localement
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
curl http://localhost:80
```

### Solutions

#### Solution 1: Le conteneur n'est pas démarré

```bash
# Vérifier via Ansible
ansible all -i inventory/static.yml \
  -m shell -a "docker ps" \
  --become

# Si le conteneur n'est pas là, redéployer
ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml
```

#### Solution 2: NSG bloque le trafic HTTP

```bash
# Vérifier les règles NSG
az network nsg rule list \
  --nsg-name nsg-vmss \
  --resource-group rg-nan_1 \
  --output table

# Vérifier que le port 80 est ouvert
# Si absent, ajouter une règle
az network nsg rule create \
  --nsg-name nsg-vmss \
  --name allow-http \
  --resource-group rg-nan_1 \
  --priority 200 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow \
  --direction Inbound
```

#### Solution 3: Le conteneur écoute sur le mauvais port

```bash
# Vérifier le mapping des ports
ansible all -i inventory/static.yml \
  -m shell -a "docker port laravel-app" \
  --become

# Résultat attendu: 80/tcp -> 0.0.0.0:80

# Si incorrect, corriger dans l'inventaire et redéployer
nano inventory/static.yml
# Modifier app_port: 80
ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml
```

#### Solution 4: Firewall local sur la VM

```bash
# SSH vers la VM
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Vérifier ufw (firewall Ubuntu)
sudo ufw status

# Si actif, autoriser le port 80
sudo ufw allow 80/tcp
```

---

## Erreur de connexion MySQL

### Symptôme

```
SQLSTATE[HY000] [2002] Connection refused
```

### Diagnostic

```bash
# Vérifier les firewall rules MySQL
az mysql flexible-server firewall-rule list \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1 \
  --output table

# Vérifier que le serveur MySQL est démarré
az mysql flexible-server show \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1 \
  --query "state" -o tsv
```

### Solutions

#### Solution 1: Ajouter la règle firewall pour le VMSS

```bash
# Récupérer l'IP publique du VMSS
VMSS_IP=$(az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query "[0].ipAddress" -o tsv)

# Ajouter une règle firewall
az mysql flexible-server firewall-rule create \
  --resource-group rg-nan_1 \
  --name tc-dev-mysql-frc-01 \
  --rule-name AllowVMSSPublicIP \
  --start-ip-address $VMSS_IP \
  --end-ip-address $VMSS_IP
```

#### Solution 2: Autoriser tout le subnet VMSS

```bash
# Via Terraform (recommandé)
cd terraform
terraform apply -target=azurerm_mysql_flexible_server_firewall_rule.vmss_to_mysql
```

#### Solution 3: Vérifier les credentials

```bash
# Tester la connexion depuis une VM
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP

# Installer mysql-client si nécessaire
sudo apt install -y mysql-client

# Tester la connexion
mysql -h tc-dev-mysql-frc-01.mysql.database.azure.com \
      -u app_admin \
      -p

# Si cela fonctionne, vérifier les variables dans le conteneur
docker exec laravel-app env | grep DB_
```

#### Solution 4: Démarrer MySQL s'il est arrêté

```bash
az mysql flexible-server start \
  --name tc-dev-mysql-frc-01 \
  --resource-group rg-nan_1
```

---

## L'auto-scaling ne fonctionne pas

### Symptôme

Le VMSS ne scale pas automatiquement malgré une charge CPU élevée.

### Diagnostic

```bash
# Vérifier la configuration d'auto-scaling
az monitor autoscale show \
  --name tc-dev-vmss-frc-01-autoscale \
  --resource-group rg-nan_1

# Vérifier les métriques CPU actuelles
az monitor metrics list \
  --resource $(az vmss show --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --query id -o tsv) \
  --metric "Percentage CPU" \
  --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
```

### Solutions

#### Solution 1: Vérifier les seuils et durées

Le CPU doit dépasser 75% pendant au moins 5 minutes pour déclencher un scale-out.

```bash
# Générer de la charge pendant au moins 10 minutes
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo apt install -y stress
stress --cpu 4 --timeout 600

# Observer le scaling dans un autre terminal
watch -n 30 'az vmss list-instances --name tc-dev-vmss-frc-01 --resource-group rg-nan_1 --output table'
```

#### Solution 2: Vérifier les limites

```bash
# Vérifier min/max instances
az monitor autoscale show \
  --name tc-dev-vmss-frc-01-autoscale \
  --resource-group rg-nan_1 \
  --query "profiles[0].capacity"

# Si max atteint, augmenter
az monitor autoscale update \
  --name tc-dev-vmss-frc-01-autoscale \
  --resource-group rg-nan_1 \
  --max-count 10
```

#### Solution 3: Vérifier le cooldown

Après un scaling, il y a une période de cooldown de 5 minutes.

```bash
# Voir l'historique des événements
az monitor activity-log list \
  --resource-group rg-nan_1 \
  --offset 2h \
  --query "[?contains(operationName.value, 'Scale')]" \
  --output table
```

---

## Inventaire Ansible ne fonctionne pas

### Symptôme

```bash
ansible-inventory -i inventory/azure_rm.yml --graph
# Empty or error
```

### Diagnostic

```bash
# Vérifier la connexion Azure
az account show

# Vérifier les dépendances Python
pip3 list | grep azure

# Tester l'inventaire dynamique
ansible-inventory -i inventory/azure_rm.yml --list
```

### Solutions

#### Solution 1: Utiliser l'inventaire statique

C'est la solution recommandée pour éviter les problèmes de compatibilité:

```bash
cd ansible

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
EOF

# Utiliser cet inventaire
ansible all -i inventory/static.yml -m ping
```

#### Solution 2: Réinstaller les dépendances Azure

```bash
# Réinstaller la collection Azure
ansible-galaxy collection install azure.azcollection --force

# Installer les dépendances Python
pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
```

---

## NSG bloque le trafic

### Symptôme

Impossible d'accéder aux services malgré une configuration correcte.

### Diagnostic

```bash
# Lister toutes les règles NSG
az network nsg rule list \
  --nsg-name nsg-vmss \
  --resource-group rg-nan_1 \
  --output table

# Vérifier les règles par défaut
az network nsg show \
  --name nsg-vmss \
  --resource-group rg-nan_1 \
  --query "defaultSecurityRules" \
  --output table
```

### Solutions

#### Solution 1: Ajouter les règles manquantes

```bash
# SSH (port 22)
az network nsg rule create \
  --resource-group rg-nan_1 \
  --nsg-name nsg-vmss \
  --name Allow-SSH \
  --priority 100 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow \
  --direction Inbound

# HTTP (port 80)
az network nsg rule create \
  --resource-group rg-nan_1 \
  --nsg-name nsg-vmss \
  --name Allow-HTTP \
  --priority 200 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow \
  --direction Inbound

# HTTPS (port 443)
az network nsg rule create \
  --resource-group rg-nan_1 \
  --nsg-name nsg-vmss \
  --name Allow-HTTPS \
  --priority 300 \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow \
  --direction Inbound
```

#### Solution 2: Autoriser MySQL sortant

```bash
az network nsg rule create \
  --resource-group rg-nan_1 \
  --nsg-name nsg-vmss \
  --name Allow-MySQL-Outbound \
  --priority 200 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 3306 \
  --destination-address-prefixes Internet
```

---

## Problèmes courants supplémentaires

### Le conteneur Laravel ne démarre pas

**Diagnostic**:

```bash
# Voir les logs du conteneur
ansible all -i inventory/static.yml -m shell \
  -a "docker logs laravel-app" -b

# Vérifier que l'image est téléchargée
ansible all -i inventory/static.yml -m shell \
  -a "docker images | grep sample-app" -b
```

**Solutions**: Vérifier les variables d'environnement, les permissions, la configuration Laravel.

### Performance lente

**Solutions**:
- Scaler verticalement (B2s → D2s)
- Optimiser l'application (cache Laravel)
- Vérifier les requêtes MySQL lentes

### Coûts trop élevés

**Solutions**:
- Réduire le nombre d'instances min/max
- Passer à un SKU inférieur (B2s → B1s)
- Configurer un shutdown automatique (dev)
- Utiliser des réservations Azure

---

## Références

- [Runbook IaaS](../runbooks/runbook-iaas.md)
- [Architecture IaaS](../reference/architecture/architecture-iaas.md)
- [Problèmes communs](common-issues.md)
- [Documentation Azure VMSS](https://learn.microsoft.com/fr-fr/azure/virtual-machine-scale-sets/)

## Support

Pour des problèmes non couverts ici:
1. Consulter les [problèmes communs](common-issues.md)
2. Vérifier les logs détaillés
3. Consulter la documentation Azure VMSS

