# Vue d'ensemble de l'architecture TERRACLOUD

## Introduction

TERRACLOUD est un projet d'Infrastructure as Code (IaC) qui illustre deux approches de déploiement d'une application web conteneurisée sur Microsoft Azure. Le projet compare les architectures **PaaS (Platform as a Service)** et **IaaS (Infrastructure as a Service)** pour héberger une application Laravel avec base de données MySQL.

## Architecture générale

```mermaid
graph TB
    subgraph "Internet"
        Users[Utilisateurs]
    end
    
    subgraph "Azure - Resource Group: rg-nan_1"
        subgraph "Infrastructure Partagée"
            VNet[Virtual Network<br/>tc-dev-vnet-frc-01<br/>10.0.0.0/16]
            ACR[Azure Container Registry<br/>tcdevacrfrc01]
            MySQL[MySQL Flexible Server<br/>tc-dev-mysql-frc-01]
        end
        
        subgraph "Approche PaaS"
            AppService[App Service<br/>tc-dev-web-frc-01]
        end
        
        subgraph "Approche IaaS"
            VMSS[VM Scale Set<br/>tc-dev-vmss-frc-01<br/>Public IPs]
        end
    end
    
    Users -->|HTTPS| AppService
    Users -->|HTTP| VMSS
    
    AppService -->|Pull Image| ACR
    AppService -->|SQL| MySQL
    
    VMSS -->|Pull Image| ACR
    VMSS -->|SQL| MySQL
    
    style AppService fill:#4CAF50
    style VMSS fill:#2196F3
    style ACR fill:#FF9800
    style MySQL fill:#00BCD4
    style VNet fill:#9E9E9E
```

## Principes architecturaux

### Infrastructure partagée

Les deux approches (PaaS et IaaS) partagent les ressources suivantes:

1. **Resource Group** (`rg-nan_1`): Conteneur logique pour toutes les ressources
2. **Virtual Network** (`tc-dev-vnet-frc-01`): Réseau privé 10.0.0.0/16
3. **Azure Container Registry** (`tcdevacrfrc01`): Registre Docker privé pour les images
4. **MySQL Flexible Server** (`tc-dev-mysql-frc-01`): Base de données managée

Cette mutualisation permet:
- Réduction des coûts (une seule base de données, un seul registre)
- Cohérence des données entre les deux déploiements
- Simplification de la gestion

### Infrastructure spécifique

Chaque approche possède ses propres ressources de compute:

**PaaS:**
- App Service Plan
- Web App

**IaaS:**
- VM Scale Set (VMs Ubuntu avec Public IPs)
- Network Security Groups spécifiques

## Choix techniques

### Conteneurisation avec Docker

L'application Laravel est conteneurisée, ce qui permet:
- Portabilité entre PaaS et IaaS
- Isolation des dépendances
- Déploiements reproductibles
- Versioning avec tags Docker

### Infrastructure as Code avec Terraform

Toute l'infrastructure est définie en code Terraform:
- Modules réutilisables
- Versioning de l'infrastructure
- Déploiements reproductibles
- Documentation intrinsèque du code

### Automatisation avec Ansible (IaaS uniquement)

Pour l'approche IaaS, Ansible gère:
- Installation de Docker sur les VMs
- Déploiement des conteneurs
- Configuration applicative
- Mises à jour coordonnées

## Environnements

Le projet supporte plusieurs environnements avec des configurations adaptées:

| Environnement | Code | VNet CIDR | Région | Politique d'arrêt |
|---------------|------|-----------|--------|-------------------|
| Développement | `dev` | 10.0.0.0/16 | France Central | 19:00-08:00 |
| Production | `prod` | 10.1.0.0/16 | France Central | 24/7 |

## Conventions de nommage

Toutes les ressources suivent le pattern Azure standard:

```
<prefix>-<env>-<type>-<region>-<index>
```

Exemples:
- VNet: `tc-dev-vnet-frc-01`
- App Service: `tc-dev-web-frc-01`
- VMSS: `tc-dev-vmss-frc-01`

Voir [conventions.md](../conventions.md) pour les détails complets.

## Sécurité

### Identité managée

Les deux approches utilisent des identités managées pour l'accès à ACR:
- Pas de stockage de credentials
- Authentification automatique via Azure AD
- Principe du moindre privilège (rôle AcrPull uniquement)

### Isolation réseau

- VNet avec subnets dédiés par fonction
- Network Security Groups (NSG) avec règles restrictives
- MySQL accessible uniquement depuis le VNet
- Accès SSH aux VMs IaaS via Public IPs individuelles

### Secrets et configuration

- Mots de passe MySQL stockés dans Terraform variables (sensibles)
- Variables d'environnement injectées dans les conteneurs
- Pas de secrets dans le code source ou les images Docker

## Comparaison des architectures

| Aspect | PaaS | IaaS |
|--------|------|------|
| **Complexité** | Simple | Complexe |
| **Nombre de ressources** | 6 | 12+ |
| **Temps de déploiement** | ~10 min | ~30 min |
| **Outils requis** | Terraform, Azure CLI | Terraform, Azure CLI, Ansible |
| **Maintenance** | Minimale | Manuelle |
| **Scalabilité** | Automatique | Configurable |
| **Contrôle** | Limité | Total |

## Flux de données

### Requête utilisateur - PaaS

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant AS as App Service
    participant DB as MySQL
    
    U->>AS: HTTPS Request
    AS->>AS: Traitement Laravel
    AS->>DB: Query SQL
    DB-->>AS: Résultats
    AS-->>U: HTTP Response
```

### Requête utilisateur - IaaS

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant VM as VM Instance (Public IP)
    participant DC as Docker Container
    participant DB as MySQL
    
    U->>VM: HTTP Request
    VM->>DC: Port 80
    DC->>DC: Traitement Laravel
    DC->>DB: Query SQL
    DB-->>DC: Résultats
    DC-->>VM: Response
    VM-->>U: HTTP Response
```

## Déploiement des images Docker

```mermaid
flowchart LR
    subgraph "Build Local"
        Code[Code Laravel] --> Docker[docker build]
    end
    
    Docker --> Push[docker push]
    Push --> ACR[Azure Container Registry]
    
    subgraph "Déploiement"
        ACR -->|Managed Identity| AppService[App Service<br/>PaaS]
        ACR -->|Managed Identity| VMSS[VM Scale Set<br/>IaaS]
    end
    
    style AppService fill:#4CAF50
    style VMSS fill:#2196F3
    style ACR fill:#FF9800
```

## Documents connexes

- [Infrastructure partagée](infrastructure-shared.md) - Détails sur les ressources communes
- [Architecture PaaS](architecture-paas.md) - Architecture détaillée de l'approche PaaS
- [Architecture IaaS](architecture-iaas.md) - Architecture détaillée de l'approche IaaS
- [Comparaison détaillée](../deployment/comparison.md) - Analyse comparative complète

