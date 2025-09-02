# Conventions TERRACLOUD

## Nommage (pattern général)
[Documentation Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
<prefix-projet>-<env>-<abbr-ressource>-<region>-<index>
- prefix-projet: tc 
- env: dev | stage | prod
- abbr-ressource: rg, vnet, snet, nsg, pip, nic, vm, vmss, asp, app, acr, kv, st
- region: weu, frc
- index: 01..99

### Exceptions Azure
- Storage Account: minuscules alphanum uniquement (ex: sttcdevweu01) [Voir ici](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- Web App: nom globalement unique
- Vérifier règles spécifiques si doute (longueur/caractères)

### Exemples (dev)
- VNet: tc-dev-vnet-frc-01
- Subnet: tc-dev-snet-frc-01
- NSG: tc-dev-nsg-frc-01
- VM: tc-dev-vm-frc-01
- App Service Plan: tc-dev-asp-frc-01
- Web App: tc-dev-app-frc-01
- ACR: tcdevacrweu01

## Tags
project=TERRACLOUD
env=dev|stage|prod
owner=etu-epitech
cost_center=nan_1
managedBy=terraform
tenant=Epitech
subscription=6b9318b1-2215-418a-b0fd-ba0832e9b333
shutdownPolicy=19:00-08:00
data_classification=internal
criticality=low
