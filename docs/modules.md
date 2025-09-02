## Choix des modules

Voici les modules que je te propose pour ton projet :

| Module       | Description              | Usage                                      |
| ------------ | ------------------------ | ------------------------------------------ |
| `rg`         | Resource Group           | Créer le RG principal (dev, prod)          |
| `network`    | VNet, subnets, NSG       | Créer le réseau pour IaaS                  |
| `acr`        | Azure Container Registry | Stocker les images Docker pour PaaS        |
| `appservice` | App Service + Plan       | Déployer la Web App pour PaaS              |
| `vm`         | VM ou VMSS               | Déployer les machines virtuelles pour IaaS |

> Pourquoi ces modules ?
>
> * Chaque module représente un **composant isolé**, facile à tester et réutiliser.
> * Respecte le principe **“DRY” (Don’t Repeat Yourself)** → n’écris pas 2 fois le même code pour dev/prod.
> * Facilite l’intégration dans GitHub Actions et Ansible plus tard.

