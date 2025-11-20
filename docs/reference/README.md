# Référence - Documentation technique

Ce dossier contient la documentation de référence technique du projet TERRACLOUD.

## Contenu

### Architecture

Documentation détaillée de l'architecture du système.

- **[Vue d'ensemble](architecture/overview.md)** - Architecture générale
- **[Infrastructure partagée](architecture/infrastructure-shared.md)** - Ressources communes
- **[Architecture PaaS](architecture/architecture-paas.md)** - Détails PaaS
- **[Architecture IaaS](architecture/architecture-iaas.md)** - Détails IaaS

### Comparaison

- **[Comparaison PaaS vs IaaS](comparison.md)** - Analyse détaillée des deux approches

### Conventions

- **[Conventions de nommage](conventions.md)** - Standards Azure du projet

## Navigation rapide

### Vous voulez comprendre...

| Sujet | Document |
|-------|----------|
| L'architecture globale | [Vue d'ensemble](architecture/overview.md) |
| Les ressources partagées | [Infrastructure partagée](architecture/infrastructure-shared.md) |
| Comment fonctionne PaaS | [Architecture PaaS](architecture/architecture-paas.md) |
| Comment fonctionne IaaS | [Architecture IaaS](architecture/architecture-iaas.md) |
| Les différences PaaS/IaaS | [Comparaison](comparison.md) |
| Les règles de nommage | [Conventions](conventions.md) |

## Documentation architecture

### [Vue d'ensemble](architecture/overview.md)

Introduction à l'architecture générale du projet:
- Principes architecturaux
- Infrastructure partagée vs spécifique
- Choix techniques
- Environnements (dev, prod)

### [Infrastructure partagée](architecture/infrastructure-shared.md)

Documentation des ressources communes aux deux approches:
- Resource Group
- Virtual Network (VNet, Subnets, NSG)
- Azure Container Registry (ACR)
- MySQL Flexible Server

### [Architecture PaaS](architecture/architecture-paas.md)

Architecture détaillée de l'approche Platform as a Service:
- App Service Plan
- Web App
- Identité managée
- Flux de déploiement et de requêtes
- Avantages et limitations

### [Architecture IaaS](architecture/architecture-iaas.md)

Architecture détaillée de l'approche Infrastructure as a Service:
- VM Scale Set (VMSS)
- Public IPs
- Auto-scaling
- Ansible pour l'automatisation
- Avantages et limitations

## Comparaison PaaS vs IaaS

Le document [comparison.md](comparison.md) offre une analyse complète:
- Comparaison technique
- Architecture comparée
- Scalabilité et performances
- Coûts détaillés
- Sécurité
- Matrice de décision
- Recommandations par cas d'usage

## Conventions de nommage

Le document [conventions.md](conventions.md) définit:
- Pattern général de nommage Azure
- Exceptions (Storage Account, ACR, Web App)
- Exemples par type de ressource
- Tags obligatoires

### Pattern général

```
<prefix-projet>-<env>-<abbr-ressource>-<region>-<index>
```

**Exemples**:
- VNet: `tc-dev-vnet-frc-01`
- VM: `tc-dev-vm-frc-01`
- App Service: `tc-dev-web-frc-01`

## Utilisation de la documentation de référence

### Pour les nouveaux arrivants

1. Commencer par la [Vue d'ensemble](architecture/overview.md)
2. Lire l'architecture correspondant à votre besoin (PaaS ou IaaS)
3. Consulter la [Comparaison](comparison.md) pour comprendre les différences

### Pour les architectes

1. [Comparaison](comparison.md) - Choisir l'approche
2. [Architecture détaillée](architecture/) - Comprendre l'implémentation
3. [Conventions](conventions.md) - Appliquer les standards

### Pour les développeurs

1. [Infrastructure partagée](architecture/infrastructure-shared.md) - Ressources communes
2. Architecture spécifique ([PaaS](architecture/architecture-paas.md) ou [IaaS](architecture/architecture-iaas.md))
3. [Conventions](conventions.md) - Nommage et tags

## Parcours de lecture

### Parcours 1: Compréhension globale (1h)

1. [Vue d'ensemble](architecture/overview.md)
2. [Infrastructure partagée](architecture/infrastructure-shared.md)
3. [Comparaison](comparison.md)

### Parcours 2: Deep dive PaaS (1h30)

1. [Vue d'ensemble](architecture/overview.md)
2. [Infrastructure partagée](architecture/infrastructure-shared.md)
3. [Architecture PaaS](architecture/architecture-paas.md)
4. [Comparaison](comparison.md)

### Parcours 3: Deep dive IaaS (2h)

1. [Vue d'ensemble](architecture/overview.md)
2. [Infrastructure partagée](architecture/infrastructure-shared.md)
3. [Architecture IaaS](architecture/architecture-iaas.md)
4. [Comparaison](comparison.md)

### Parcours 4: Décision architecturale (30min)

1. [Comparaison](comparison.md)
2. Architecture correspondante (PaaS ou IaaS)

## Schémas et diagrammes

Tous les documents d'architecture utilisent des diagrammes Mermaid.js pour illustrer:
- Architectures réseau
- Flux de déploiement
- Séquences de requêtes
- Processus d'auto-scaling

Ces schémas sont rendus automatiquement par GitHub et les lecteurs Markdown modernes.

## Glossaire

### Acronymes Azure

- **ACR**: Azure Container Registry
- **ASP**: App Service Plan
- **NSG**: Network Security Group
- **PIP**: Public IP
- **RG**: Resource Group
- **VMSS**: Virtual Machine Scale Set
- **VNet**: Virtual Network

### Concepts

- **PaaS**: Platform as a Service - Services cloud managés
- **IaaS**: Infrastructure as a Service - Serveurs virtuels
- **IaC**: Infrastructure as Code - Infrastructure définie en code
- **SKU**: Stock Keeping Unit - Niveau de service Azure
- **Managed Identity**: Identité managée Azure AD

## Liens vers autre documentation

### Documentation opérationnelle

- [Runbooks](../runbooks/README.md) - Procédures de déploiement
- [Operations](../operations/README.md) - Opérations quotidiennes
- [Troubleshooting](../troubleshooting/README.md) - Dépannage

### Documentation utilisateur

- [Guides](../guides/README.md) - Guides pratiques
- [Getting Started](../guides/getting-started.md) - Démarrage rapide

## Ressources externes

- [Microsoft Azure Documentation](https://learn.microsoft.com/fr-fr/azure/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

Pour des questions sur l'architecture:
1. Consulter cette documentation de référence
2. Consulter la documentation Azure officielle
3. Ouvrir une discussion sur le projet

---

**Dernière mise à jour**: 2024
**Projet**: TERRACLOUD - Epitech T-CLO-900

