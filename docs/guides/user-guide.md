# Guide utilisateur - Application TERRACLOUD

Guide d'utilisation de l'application Laravel déployée sur Azure.

## Accès à l'application

### URLs de l'application

#### PaaS (App Service)
```
https://tc-dev-web-frc-01.azurewebsites.net    # Dev
https://tc-prod-web-frc-01.azurewebsites.net   # Prod
```

#### IaaS (VM Scale Set)
```
http://<INSTANCE_IP>                            # Dev (HTTP)
https://<DOMAIN>                                # Prod (HTTPS avec domaine)
```

Pour obtenir l'IP d'une instance VMSS:
```bash
az vmss list-instance-public-ips \
  --name tc-dev-vmss-frc-01 \
  --resource-group rg-nan_1 \
  --query "[0].ipAddress" -o tsv
```

## Fonctionnalités de l'application

### Page d'accueil

L'application Laravel affiche une page d'accueil standard avec:
- Logo Laravel
- Liens vers la documentation
- Informations sur la version

### API REST

L'application expose une API REST pour la gestion des ressources.

#### Endpoints disponibles

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Page d'accueil |
| GET | `/api/health` | Health check |
| GET | `/api/status` | Statut de l'application |

#### Exemples d'utilisation

**Health check**:
```bash
curl https://tc-dev-web-frc-01.azurewebsites.net/api/health

# Réponse attendue:
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Statut de l'application**:
```bash
curl https://tc-dev-web-frc-01.azurewebsites.net/api/status

# Réponse attendue:
{
  "app": "TERRACLOUD",
  "version": "1.0.0",
  "environment": "dev",
  "database": "connected"
}
```

## Connexion à la base de données

L'application est connectée à MySQL Flexible Server sur Azure.

### Informations de connexion

- **Host**: `tc-dev-mysql-frc-01.mysql.database.azure.com`
- **Port**: `3306`
- **Database**: `app_database`
- **User**: `app_admin`
- **Password**: (configuré dans les variables d'environnement)

### Tester la connexion

```bash
# Depuis l'application (PaaS)
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1
mysql -h tc-dev-mysql-frc-01.mysql.database.azure.com -u app_admin -p

# Depuis une VM (IaaS)
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
mysql -h tc-dev-mysql-frc-01.mysql.database.azure.com -u app_admin -p
```

## Migrations de base de données

### Exécuter les migrations

**PaaS**:
```bash
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1
cd /var/www/html
php artisan migrate
```

**IaaS**:
```bash
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo docker exec -it laravel-app php artisan migrate
```

### Migrations disponibles

L'application inclut des migrations pour:
- Création des tables utilisateurs
- Création des tables sessions
- Configuration initiale

## Configuration de l'application

### Variables d'environnement

L'application utilise les variables d'environnement suivantes:

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `APP_ENV` | Environnement | `production` |
| `APP_DEBUG` | Mode debug | `false` |
| `APP_KEY` | Clé de chiffrement | Auto-généré |
| `DB_HOST` | Hôte MySQL | Azure MySQL FQDN |
| `DB_PORT` | Port MySQL | `3306` |
| `DB_DATABASE` | Nom de la base | `app_database` |
| `DB_USERNAME` | Utilisateur MySQL | `app_admin` |
| `DB_PASSWORD` | Mot de passe MySQL | Configuré |

### Modifier la configuration

**PaaS**:
```bash
az webapp config appsettings set \
  --name tc-dev-web-frc-01 \
  --resource-group rg-nan_1 \
  --settings "APP_DEBUG=true"
```

**IaaS**:
Modifier l'inventaire Ansible (`inventory/static.yml`) et redéployer.

## Logs de l'application

### Consulter les logs

**PaaS**:
```bash
# Logs en temps réel
az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1

# Logs Laravel spécifiques
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1
tail -f /var/www/html/storage/logs/laravel.log
```

**IaaS**:
```bash
# Logs du conteneur
ssh -i ~/.ssh/terracloud-dev-key azureuser@$INSTANCE_IP
sudo docker logs laravel-app -f

# Logs Laravel
sudo docker exec -it laravel-app tail -f storage/logs/laravel.log
```

## Performance et optimisation

### Cache

L'application utilise le cache Laravel pour optimiser les performances:

```bash
# Activer le cache
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Vider le cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

### Optimisation automatique

```bash
# Optimiser toute l'application
php artisan optimize

# Mode production (après déploiement)
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## Sécurité

### HTTPS

- **PaaS**: HTTPS activé par défaut avec certificat Azure managé
- **IaaS**: HTTPS configurable via Let's Encrypt (voir runbook IaaS)

### Authentification

L'application peut inclure une authentification Laravel Breeze/Sanctum (selon configuration).

### Protection CSRF

Laravel inclut une protection CSRF par défaut pour tous les formulaires.

## Maintenance

### Mode maintenance

Activer le mode maintenance:

```bash
# PaaS
az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1
php artisan down

# Désactiver
php artisan up
```

### Mise à jour de l'application

Voir les [Runbooks](../runbooks/README.md) pour les procédures de mise à jour.

## Dépannage utilisateur

### L'application ne répond pas

1. Vérifier que l'URL est correcte
2. Vérifier que les ressources Azure sont démarrées
3. Consulter les logs
4. Voir le [guide de troubleshooting](../troubleshooting/README.md)

### Erreur 500 Internal Server Error

Causes possibles:
- Variables d'environnement manquantes
- Connexion MySQL échouée
- Erreur dans le code

**Solution**:
1. Consulter les logs Laravel
2. Vérifier la configuration
3. Voir le troubleshooting correspondant (PaaS ou IaaS)

### Page blanche

Causes possibles:
- Erreur PHP fatale
- Permissions de fichiers
- Mémoire insuffisante

**Solution**:
1. Activer le mode debug (`APP_DEBUG=true`)
2. Consulter les logs
3. Vérifier les permissions

## Support

Pour toute question ou problème:
1. Consulter ce guide utilisateur
2. Consulter le [guide de troubleshooting](../troubleshooting/README.md)
3. Consulter les logs de l'application
4. Contacter l'équipe de support

## Ressources

- [Laravel Documentation](https://laravel.com/docs)
- [PHP Documentation](https://www.php.net/docs.php)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Troubleshooting](../troubleshooting/README.md)

---

**Dernière mise à jour**: 2024
**Projet**: TERRACLOUD - Epitech T-CLO-900

