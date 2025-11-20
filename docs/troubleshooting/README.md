# Troubleshooting - Guides de dépannage

Ce dossier contient tous les guides de dépannage pour résoudre les problèmes du projet TERRACLOUD.

## Organisation

Les guides sont organisés par type de déploiement et de technologie :

### Par déploiement

- **[PaaS](paas-troubleshooting.md)** - Problèmes spécifiques à Azure App Service
- **[IaaS](iaas-troubleshooting.md)** - Problèmes spécifiques à VM Scale Set
- **[CI/CD](cicd-troubleshooting.md)** - Problèmes avec GitHub Actions
- **[Scripts](scripts-troubleshooting.md)** - Problèmes avec les scripts bash

### Par technologie

- **[Problèmes communs](common-issues.md)** - Azure, Terraform, Docker, Réseau

## Guide de navigation rapide

### Vous rencontrez un problème avec...

| Problème | Guide à consulter |
|----------|-------------------|
| L'application ne démarre pas (PaaS) | [PaaS Troubleshooting](paas-troubleshooting.md#lapplication-ne-démarre-pas) |
| Les VMs ne sont pas accessibles | [IaaS Troubleshooting](iaas-troubleshooting.md#les-vms-ne-sont-pas-accessibles-via-ssh) |
| Erreur de connexion MySQL | [PaaS](paas-troubleshooting.md#erreur-de-connexion-à-mysql) ou [IaaS](iaas-troubleshooting.md#erreur-de-connexion-mysql) |
| Workflow GitHub Actions échoue | [CI/CD Troubleshooting](cicd-troubleshooting.md) |
| Script bash échoue | [Scripts Troubleshooting](scripts-troubleshooting.md) |
| Terraform state lock | [Problèmes communs](common-issues.md#state-lock-bloqué) |
| Docker build échoue | [Problèmes communs](common-issues.md#impossible-de-build-limage) |
| Coûts trop élevés | [Problèmes communs](common-issues.md#facture-plus-élevée-que-prévu) |
| ACR login failed | [Problèmes communs](common-issues.md#push-vers-acr-échoue) |
| NSG bloque le trafic | [IaaS Troubleshooting](iaas-troubleshooting.md#nsg-bloque-le-trafic) |
| Ansible ne fonctionne pas | [IaaS Troubleshooting](iaas-troubleshooting.md#inventaire-ansible-ne-fonctionne-pas) |

## Format des guides

Chaque guide suit le format standardisé :

### Structure

```markdown
## Nom du problème

### Symptôme
Description du symptôme observé

### Diagnostic
Commandes pour diagnostiquer le problème

### Solutions
#### Solution 1: ...
Étapes de résolution

#### Solution 2: ...
Alternative
```

### Commandes complètes

Toutes les commandes sont prêtes à copier-coller avec les valeurs réelles (pas de placeholders génériques).

## Méthodologie de dépannage

### 1. Identifier le symptôme

Notez précisément :
- Le message d'erreur exact
- Le contexte (quelle commande, quel moment)
- L'environnement (dev/prod, PaaS/IaaS)

### 2. Consulter le bon guide

- Problème spécifique à un type de déploiement → Guide PaaS/IaaS
- Problème dans GitHub Actions → Guide CI/CD
- Problème dans un script → Guide Scripts
- Problème général → Problèmes communs

### 3. Suivre le diagnostic

Exécuter les commandes de diagnostic pour confirmer la cause.

### 4. Appliquer la solution

Suivre les étapes dans l'ordre, vérifier après chaque étape.

### 5. Documenter

Si le problème n'est pas documenté, contribuer à l'amélioration des guides.

## Problèmes les plus fréquents

### Top 10 des problèmes

1. **Connexion MySQL refusée** → Firewall rules
2. **SSH connection refused** → Clés SSH ou NSG
3. **Docker pull failed** → Permissions ACR
4. **Terraform state lock** → Déploiement interrompu
5. **Application ne démarre pas** → Variables d'environnement
6. **Ansible timeout** → cloud-init pas terminé
7. **ACR login failed** → Permissions manquantes
8. **NSG bloque le trafic** → Règles manquantes
9. **Workflow bloqué** → Approbation requise
10. **Coûts élevés** → Ressources non arrêtées

## Arbre de décision

```
Problème
├─ Déploiement
│  ├─ PaaS → paas-troubleshooting.md
│  └─ IaaS → iaas-troubleshooting.md
├─ CI/CD
│  └─ GitHub Actions → cicd-troubleshooting.md
├─ Scripts
│  └─ Bash/Makefile → scripts-troubleshooting.md
└─ Général
   ├─ Azure → common-issues.md#problèmes-azure
   ├─ Terraform → common-issues.md#problèmes-terraform
   ├─ Docker → common-issues.md#problèmes-docker
   └─ Réseau → common-issues.md#problèmes-réseau
```

## Ressources complémentaires

### Documentation du projet

- [Runbooks](../runbooks/README.md) - Procédures opérationnelles
- [Opérations](../operations/README.md) - Guides de référence
- [Architecture](../reference/architecture/overview.md) - Comprendre l'infrastructure

### Documentation externe

- [Azure Troubleshooting](https://learn.microsoft.com/fr-fr/azure/troubleshoot/)
- [Terraform Debugging](https://www.terraform.io/docs/internals/debugging.html)
- [Docker Troubleshooting](https://docs.docker.com/config/troubleshoot/)
- [Ansible Debugging](https://docs.ansible.com/ansible/latest/user_guide/playbooks_debugger.html)

## Support

### Processus de support

1. **Self-service** : Consulter ce dossier troubleshooting
2. **Logs** : Examiner les logs détaillés
3. **Documentation** : Vérifier la documentation officielle
4. **Community** : Chercher sur Stack Overflow, GitHub Issues
5. **Support Azure** : Ouvrir un ticket si nécessaire

### Collecter les informations

Avant de demander de l'aide, collecter :

```bash
# Version des outils
az --version
terraform --version
ansible --version
docker --version

# Informations Azure
az account show
az resource list --resource-group rg-nan_1 --output table

# Logs récents
# (selon le type de déploiement)
```

## Contribution

### Améliorer les guides

Si vous rencontrez un problème non documenté :

1. Résoudre le problème
2. Documenter la solution
3. Ajouter au guide approprié
4. Format : Symptôme → Diagnostic → Solutions

### Template de contribution

```markdown
## Nouveau problème

### Symptôme
Description claire et concise

### Diagnostic
```bash
# Commandes de diagnostic
```

### Solutions

#### Solution 1: Nom de la solution
```bash
# Étapes de résolution
```
Description du pourquoi
```

---

**Dernière mise à jour** : 2024
**Projet** : TERRACLOUD - Epitech T-CLO-900

