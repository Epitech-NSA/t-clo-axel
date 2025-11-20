# Runbook: Destruction de l'infrastructure

## Objectif

Supprimer proprement les ressources Azure déployées pour éviter les coûts inutiles.

**⚠️ ATTENTION**: Cette procédure est IRRÉVERSIBLE. Toutes les données seront perdues.

## Prérequis

- Azure CLI connecté
- Terraform initialisé
- Accès au workspace concerné

## Vérifications avant destruction

### Étape 1: Sauvegarder les données importantes

```bash
# Sauvegarder la base de données (si nécessaire)
mysqldump -h tc-dev-mysql-frc-01.mysql.database.azure.com \
          -u app_admin -p \
          app_database > backup_$(date +%Y%m%d_%H%M%S).sql

# Sauvegarder la state Terraform
cd terraform
terraform state pull > backup-state-$(date +%Y%m%d).tfstate
```

**Checkpoint**: Sauvegardes effectuées

### Étape 2: Lister les ressources à détruire

```bash
cd terraform
terraform workspace select dev  # ou prod

# Voir les ressources
terraform state list

# Voir le plan de destruction
terraform plan -destroy
```

**Checkpoint**: Ressources identifiées

## Procédures de destruction

### Option 1: Détruire uniquement le PaaS

```bash
cd terraform
terraform workspace select dev

# Détruire seulement l'App Service
terraform destroy -target=module.appservice

# Confirmer avec 'yes'
```

**Temps estimé**: 2-3 minutes

**Checkpoint**: PaaS détruit

### Option 2: Détruire uniquement l'IaaS

```bash
cd terraform
terraform workspace select dev

# Détruire le VMSS et ses dépendances
terraform destroy -target=module.vmss \
                  -target=azurerm_role_assignment.vmss_acr_pull \
                  -target=azurerm_mysql_flexible_server_firewall_rule.vmss_to_mysql

# Confirmer avec 'yes'
```

**Temps estimé**: 5-8 minutes

**Checkpoint**: IaaS détruit

### Option 3: Détruire toute l'infrastructure

```bash
cd terraform
terraform workspace select dev

# Détruire tout
terraform destroy

# Confirmer avec 'yes'
```

**⚠️ ATTENTION**: Cela supprime TOUT (VNet, ACR, MySQL, PaaS, IaaS)

**Temps estimé**: 10-15 minutes

**Checkpoint**: Toute l'infrastructure détruite

## Vérification de la destruction

### Vérifier dans Azure

```bash
# Vérifier les ressources restantes
az resource list \
  --resource-group rg-nan_1 \
  --output table

# Vérifier les App Services
az webapp list --resource-group rg-nan_1 --output table

# Vérifier les VMSS
az vmss list --resource-group rg-nan_1 --output table

# Vérifier les bases de données
az mysql flexible-server list --resource-group rg-nan_1 --output table
```

### Vérifier dans Terraform

```bash
cd terraform

# State doit être vide (ou ne montrer que les ressources non-détruites)
terraform state list

# Vérifier qu'aucune ressource n'est en attente
terraform plan
```

**Checkpoint**: Destruction confirmée

## Nettoyage final

### Supprimer les fichiers locaux

```bash
# Nettoyer les fichiers Terraform
cd terraform
rm -rf .terraform/
rm -f .terraform.lock.hcl
rm -f terraform.tfstate.d/

# Nettoyer les images Docker locales
docker images | grep sample-app
docker rmi tcdevacrfrc01.azurecr.io/sample-app:latest
```

### Supprimer le workspace Terraform

```bash
cd terraform

# Basculer vers le workspace par défaut
terraform workspace select default

# Supprimer le workspace dev ou prod
terraform workspace delete dev
```

**Checkpoint**: Nettoyage final effectué

## Destruction par environnement

### Développement (dev)

```bash
cd terraform
terraform workspace select dev

# Destruction rapide du dev
terraform destroy

# Confirmer
yes
```

### Production (prod)

**⚠️ DOUBLE VÉRIFICATION REQUISE**

```bash
cd terraform

# S'assurer d'être sur prod
terraform workspace show

# Vérifier ce qui sera détruit
terraform plan -destroy

# Demander confirmation à l'équipe
echo "Destruction de PRODUCTION - Êtes-vous sûr? (yes/no)"
read CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  terraform destroy
fi
```

## Checklist de destruction

### Avant destruction

- [ ] Sauvegarder la base de données
- [ ] Sauvegarder la state Terraform
- [ ] Vérifier le workspace actif
- [ ] Informer l'équipe (pour prod)
- [ ] Vérifier qu'aucune opération critique n'est en cours

### Pendant destruction

- [ ] Confirmer la destruction dans Terraform
- [ ] Surveiller les logs d'erreur
- [ ] Noter les ressources qui ne peuvent pas être détruites

### Après destruction

- [ ] Vérifier dans Azure Portal
- [ ] Vérifier avec `az resource list`
- [ ] Vérifier `terraform state list`
- [ ] Supprimer les ressources manuelles restantes
- [ ] Nettoyer les fichiers locaux
- [ ] Supprimer le workspace Terraform

## Cas particuliers

### Si la destruction échoue

```bash
# Identifier la ressource bloquante
terraform destroy -target=<ressource-spécifique>

# Forcer le unlock si nécessaire
terraform force-unlock <LOCK_ID>

# Supprimer manuellement dans Azure
az resource delete --ids <resource-id>

# Supprimer de la state Terraform
terraform state rm <ressource>
```

### Ressources protégées

Certaines ressources peuvent avoir un verrou de suppression:

```bash
# Lister les verrous
az lock list --resource-group rg-nan_1

# Supprimer un verrou si nécessaire
az lock delete --name <lock-name> --resource-group rg-nan_1
```

### Destruction partielle (garder les données)

Pour garder la base de données mais supprimer le reste:

```bash
# Détruire tout sauf MySQL
terraform destroy -target=module.appservice \
                  -target=module.vmss \
                  -target=module.acr

# MySQL reste en place
```

## Script de destruction automatique

Pour une destruction rapide en développement:

```bash
#!/bin/bash
# destroy-dev.sh

cd terraform
terraform workspace select dev

echo "Destruction de l'environnement DEV..."
terraform destroy -auto-approve

echo "Nettoyage..."
rm -rf .terraform/
terraform workspace select default
terraform workspace delete dev

echo "Destruction terminée!"
```

**⚠️ N'utilisez PAS -auto-approve en production**

## Coûts après destruction

| Scénario | Ressources restantes | Coût mensuel |
|----------|---------------------|--------------|
| Destruction totale | Aucune | 0€ |
| PaaS détruit seul | VNet, ACR, MySQL, IaaS | ~53€ |
| IaaS détruit seul | VNet, ACR, MySQL, PaaS | ~32€ |
| Garder MySQL seul | MySQL uniquement | ~15€ |

## Références

- [Guide des scripts](../operations/scripts-reference.md)
- [Troubleshooting commun](../troubleshooting/common-issues.md)

## Support

En cas de problème lors de la destruction, consultez le [guide de troubleshooting](../troubleshooting/common-issues.md).

## Notes importantes

1. **Sauvegardes**: Toujours sauvegarder avant de détruire
2. **Vérification**: Vérifier le workspace actif
3. **Confirmation**: Lire attentivement ce qui sera détruit
4. **Production**: Double vérification requise
5. **Ressources externes**: Certaines ressources peuvent être en dehors de Terraform

