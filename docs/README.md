# Documentation TERRACLOUD

Bienvenue dans la documentation complète du projet TERRACLOUD - Infrastructure as Code sur Microsoft Azure.

## Navigation rapide

| Vous êtes... | Commencez par... |
|--------------|------------------|
| Nouveau sur le projet | [Guide de démarrage rapide](guides/getting-started.md) |
| Utilisateur de l'application | [Guide utilisateur](guides/user-guide.md) |
| Déploiement PaaS | [Guide de déploiement PaaS](deployment/deployment-paas.md) |
| Déploiement IaaS | [Guide de déploiement IaaS](deployment/deployment-iaas.md) |
| Comparer les approches | [Comparaison PaaS vs IaaS](deployment/comparison.md) |
| Comprendre l'architecture | [Vue d'ensemble architecturale](architecture/overview.md) |

## Table des matières

### 1. Guides pratiques

#### Pour débuter

- **[Guide de démarrage rapide](guides/getting-started.md)**
  - Installation des outils (Azure CLI, Terraform, Docker)
  - Configuration initiale
  - Premier déploiement PaaS en 30 minutes
  - Vérification et tests

- **[Guide utilisateur](guides/user-guide.md)**
  - Accéder à l'application déployée
  - Fonctionnalités disponibles
  - API REST
  - Parcours utilisateur
  - Dépannage utilisateur

#### Pour déployer

- **[Déploiement PaaS - Azure App Service](deployment/deployment-paas.md)**
  - Prérequis détaillés
  - Déploiement pas à pas (15 minutes)
  - Configuration avancée
  - Monitoring et logs
  - Scaling
  - Dépannage complet
  - Coûts estimés

- **[Déploiement IaaS - VM Scale Set](deployment/deployment-iaas.md)**
  - Prérequis détaillés
  - Génération de clés SSH
  - Déploiement infrastructure (15-20 minutes)
  - Configuration Ansible
  - Déploiement application (10 minutes)
  - Auto-scaling
  - Opérations courantes
  - Dépannage complet
  - Coûts estimés

- **[Comparaison PaaS vs IaaS](deployment/comparison.md)**
  - Comparaison technique détaillée
  - Architecture comparée
  - Complexité de déploiement
  - Scalabilité et performances
  - Coûts détaillés
  - Sécurité
  - Flexibilité et contrôle
  - Matrice de décision
  - Recommandations par cas d'usage

### 2. Architecture

#### Vue d'ensemble

- **[Vue d'ensemble de l'architecture](architecture/overview.md)**
  - Architecture générale du projet
  - Principes architecturaux
  - Infrastructure partagée vs spécifique
  - Choix techniques
  - Environnements (dev, prod)
  - Conventions de nommage
  - Sécurité globale
  - Flux de données

#### Infrastructure

- **[Infrastructure partagée](architecture/infrastructure-shared.md)**
  - Resource Group
  - Virtual Network (VNet, Subnets, NSG)
  - Azure Container Registry (ACR)
  - MySQL Flexible Server
  - Configuration réseau détaillée
  - Règles de sécurité
  - Coûts

- **[Architecture PaaS](architecture/architecture-paas.md)**
  - App Service Plan
  - Web App
  - Identité managée
  - Flux de déploiement
  - Flux de requêtes utilisateur
  - Sécurité PaaS
  - Monitoring
  - Haute disponibilité
  - Avantages et limitations
  - Cas d'usage recommandés

- **[Architecture IaaS](architecture/architecture-iaas.md)**
  - Public IP
  - Load Balancer (règles, health probes, NAT)
  - VM Scale Set (VMSS)
  - Architecture des VMs
  - Auto-scaling détaillé
  - Ansible - Automatisation
  - Flux de déploiement IaaS
  - Conteneurs Docker sur VMs
  - Sécurité IaaS
  - Avantages et limitations
  - Cas d'usage recommandés

### 3. Références

- **[Conventions de nommage](conventions.md)**
  - Pattern général de nommage Azure
  - Exceptions (Storage Account, ACR, Web App)
  - Exemples pour chaque type de ressource
  - Tags obligatoires
  - Documentation officielle Azure

## Organisation de la documentation

```
docs/
├── README.md                      # Ce fichier (index)
├── conventions.md                 # Conventions de nommage Azure
│
├── guides/                        # Guides pratiques
│   ├── getting-started.md         # Premier déploiement
│   └── user-guide.md              # Guide utilisateur
│
├── deployment/                    # Guides de déploiement
│   ├── deployment-paas.md         # Déploiement PaaS complet
│   ├── deployment-iaas.md         # Déploiement IaaS complet
│   └── comparison.md              # Comparaison détaillée
│
└── architecture/                  # Documentation architecturale
    ├── overview.md                # Vue d'ensemble
    ├── infrastructure-shared.md   # Infrastructure partagée
    ├── architecture-paas.md       # Architecture PaaS
    └── architecture-iaas.md       # Architecture IaaS
```

## Parcours de lecture recommandés

### Parcours 1: Débutant - Premier déploiement

1. [Guide de démarrage rapide](guides/getting-started.md)
2. [Déploiement PaaS](deployment/deployment-paas.md)
3. [Guide utilisateur](guides/user-guide.md)
4. [Vue d'ensemble architecturale](architecture/overview.md)

**Temps estimé:** 2-3 heures

### Parcours 2: DevOps - Comprendre l'infrastructure

1. [Vue d'ensemble architecturale](architecture/overview.md)
2. [Infrastructure partagée](architecture/infrastructure-shared.md)
3. [Architecture PaaS](architecture/architecture-paas.md)
4. [Architecture IaaS](architecture/architecture-iaas.md)
5. [Comparaison PaaS vs IaaS](deployment/comparison.md)

**Temps estimé:** 1-2 heures

### Parcours 3: Projet complet - Déployer les deux approches

1. [Guide de démarrage rapide](guides/getting-started.md)
2. [Déploiement PaaS](deployment/deployment-paas.md)
3. [Déploiement IaaS](deployment/deployment-iaas.md)
4. [Comparaison PaaS vs IaaS](deployment/comparison.md)
5. [Guide utilisateur](guides/user-guide.md)

**Temps estimé:** 4-5 heures

### Parcours 4: Analyse comparative - Choisir l'approche

1. [Vue d'ensemble architecturale](architecture/overview.md)
2. [Architecture PaaS](architecture/architecture-paas.md)
3. [Architecture IaaS](architecture/architecture-iaas.md)
4. [Comparaison PaaS vs IaaS](deployment/comparison.md)

**Temps estimé:** 1 heure

## Concepts clés

### Infrastructure as Code (IaC)

Toute l'infrastructure est définie en code Terraform, permettant:
- Versioning de l'infrastructure
- Déploiements reproductibles
- Documentation intrinsèque
- Gestion des environnements multiples

### Approches de déploiement

**PaaS (Platform as a Service):**
- Azure App Service gère l'infrastructure
- Déploiement simplifié
- Maintenance automatique
- Idéal pour applications standard

**IaaS (Infrastructure as a Service):**
- Contrôle total sur les VMs
- Configuration personnalisée
- Automatisation via Ansible
- Idéal pour besoins spécifiques

### Technologies utilisées

| Technologie | Usage | Documentation |
|-------------|-------|---------------|
| **Terraform** | Infrastructure as Code | [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) |
| **Ansible** | Automatisation IaaS | [Ansible Azure Collection](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/) |
| **Docker** | Conteneurisation | [Docker Documentation](https://docs.docker.com/) |
| **Laravel** | Framework PHP | [Laravel Documentation](https://laravel.com/docs) |
| **MySQL** | Base de données | [Azure MySQL](https://learn.microsoft.com/fr-fr/azure/mysql/) |

## Schémas et diagrammes

La documentation utilise des schémas Mermaid.js intégrés pour illustrer:
- Architectures réseau
- Flux de déploiement
- Séquences de requêtes
- Processus d'auto-scaling
- Comparaisons visuelles

Ces schémas sont rendus automatiquement par GitHub et la plupart des lecteurs Markdown modernes.

## Glossaire

### Acronymes Azure

- **ACR**: Azure Container Registry
- **ASP**: App Service Plan
- **LB**: Load Balancer
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
- **NAT**: Network Address Translation - Traduction d'adresses
- **Health Probe**: Sonde de santé pour monitoring
- **Managed Identity**: Identité managée Azure AD

## Conventions documentaires

### Structure des documents

Chaque document de cette documentation suit une structure cohérente:

1. **Introduction** - Contexte et objectifs
2. **Prérequis** - Ce dont vous avez besoin
3. **Instructions pas à pas** - Procédures détaillées
4. **Exemples** - Code et commandes
5. **Dépannage** - Solutions aux problèmes courants
6. **Références** - Liens vers autres documents

### Blocs de code

Les exemples de code incluent:
- Syntaxe colorée selon le langage
- Commentaires explicatifs
- Commandes complètes prêtes à copier

### Notes et avertissements

- **Important:** Informations critiques
- **Attention:** Actions potentiellement dangereuses
- **Note:** Informations complémentaires
- **Astuce:** Conseils pratiques

## Contribution à la documentation

### Principes de rédaction

- Style professionnel et humain
- Français correct et technique
- Pas d'émojis (sauf exceptions)
- Schémas Mermaid.js pour les visualisations
- Exemples de code concrets
- Liens de navigation entre documents

### Structure Markdown

- Titres hiérarchisés (`#`, `##`, `###`)
- Tableaux pour les comparaisons
- Listes pour les énumérations
- Blocs de code avec syntaxe
- Liens relatifs entre documents

## Support et ressources

### Documentation officielle

- [Microsoft Azure Documentation](https://learn.microsoft.com/fr-fr/azure/)
- [Terraform Registry](https://registry.terraform.io/)
- [Ansible Documentation](https://docs.ansible.com/)

### Projet TERRACLOUD

- [README principal](../README.md) - Vue d'ensemble du projet
- [Code source](../) - Repository complet
- Epitech T-CLO-900

## Informations de version

- **Projet:** TERRACLOUD
- **Version documentation:** 1.0
- **Dernière mise à jour:** 2024
- **Environnement cible:** Azure France Central
- **Frameworks:** Terraform 1.0+, Ansible 2.9+

---

**Navigation:**
- [Retour au README principal](../README.md)
- [Guide de démarrage rapide](guides/getting-started.md)
- [Vue d'ensemble architecturale](architecture/overview.md)

**Projet éducatif - Epitech 2025**

