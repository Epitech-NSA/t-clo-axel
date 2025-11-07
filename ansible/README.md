# Ansible Configuration for IaaS Deployment

This directory contains Ansible playbooks and roles for automating the deployment of the Laravel application to Azure VM Scale Set.

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   └── azure_rm.yml        # Azure dynamic inventory
├── group_vars/
│   └── all.yml             # Common variables
├── roles/
│   ├── docker/             # Docker installation role
│   │   ├── tasks/
│   │   ├── handlers/
│   │   └── defaults/
│   └── app-deploy/         # Application deployment role
│       ├── tasks/
│       ├── templates/
│       └── defaults/
└── playbooks/
    ├── site.yml            # Complete deployment
    ├── docker-only.yml     # Docker installation only
    └── deploy-app.yml      # Application deployment only
```

## Prerequisites

1. **Ansible installed**:
   ```bash
   pip3 install ansible
   ```

2. **Azure collection**:
   ```bash
   ansible-galaxy collection install azure.azcollection
   pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
   ```

3. **Azure CLI authenticated**:
   ```bash
   az login
   az account set --subscription "6b9318b1-2215-418a-b0fd-ba0832e9b333"
   ```

4. **VMSS already deployed** via Terraform

## Quick Start

### 1. Test Inventory

```bash
# List all hosts
ansible-inventory -i inventory/azure_rm.yml --graph

# List all hosts with details
ansible-inventory -i inventory/azure_rm.yml --list

# Test connectivity
ansible all -i inventory/azure_rm.yml -m ping
```

### 2. Run Complete Deployment

```bash
# Install Docker + Deploy Application
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml
```

### 3. Install Docker Only

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/docker-only.yml
```

### 4. Deploy/Update Application Only

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/deploy-app.yml
```

## Playbook Details

### site.yml
Complete deployment including:
- Docker installation
- ACR authentication
- Application container deployment
- Database migrations
- Health checks

**Usage:**
```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml
```

### docker-only.yml
Only installs Docker on all VMs. Useful for:
- Initial setup
- Docker version updates
- Troubleshooting

**Usage:**
```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/docker-only.yml
```

### deploy-app.yml
Only deploys the application. Useful for:
- Application updates
- Configuration changes
- Quick redeployment

**Usage:**
```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/deploy-app.yml
```

## Configuration

### Updating Variables

Edit `group_vars/all.yml` to change:
- ACR details
- Docker image name/tag
- MySQL connection settings
- Application settings

### Override Variables

Use `-e` flag to override variables:

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/deploy-app.yml \
  -e "docker_image_tag=v2.0" \
  -e "mysql_password=NewPassword"
```

## Advanced Usage

### Target Specific Hosts

```bash
# Deploy to development environment only
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml --limit "env_dev"

# Deploy to specific IP
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml --limit "10.0.3.4"
```

### Run Specific Tags

```bash
# Only run Docker tasks
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml --tags "docker"

# Only run application deployment
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml --tags "app"
```

### Rolling Updates

Deploy to one host at a time:

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/deploy-app.yml --serial 1
```

### Dry Run (Check Mode)

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml --check
```

### Verbose Output

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml -v   # verbose
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml -vv  # more verbose
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml -vvv # debug
```

## Troubleshooting

### Inventory Not Working

```bash
# Check Azure CLI authentication
az account show

# Manually list VMSS instances
az vmss list-instances --name tc-dev-vmss-frc-01 --resource-group rg-nan_1

# Check inventory plugin
ansible-inventory -i inventory/azure_rm.yml --list
```

### SSH Connection Issues

```bash
# Test direct SSH
ssh azureuser@<VM_IP>

# Check SSH key
ls -la ~/.ssh/

# Use different SSH key
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml \
  --private-key ~/.ssh/terracloud-key
```

### Slow Execution

```bash
# Enable pipelining (already in ansible.cfg)
# Use fact caching
# Reduce gather_facts if not needed
```

### ACR Authentication Fails

```bash
# Login to VM and test manually
ssh azureuser@<VM_IP>
az login --identity
az acr login --name tcdevacrfrc01
```

## Security Notes

1. **Secrets Management**: 
   - Use Ansible Vault for sensitive data
   - Or use Azure Key Vault integration

2. **SSH Keys**:
   - Keep private keys secure
   - Use SSH agent forwarding if needed

3. **Sudo Access**:
   - Playbooks use `become: yes` for privileged operations
   - Ensure sudoers is configured correctly

## Common Tasks

### View Container Logs

```bash
ansible all -i inventory/azure_rm.yml -m shell \
  -a "docker logs laravel-app --tail 50" --become
```

### Restart Application

```bash
ansible all -i inventory/azure_rm.yml -m shell \
  -a "docker restart laravel-app" --become
```

### Check Container Status

```bash
ansible all -i inventory/azure_rm.yml -m shell \
  -a "docker ps" --become
```

### Update and Restart All

```bash
ansible-playbook -i inventory/azure_rm.yml playbooks/deploy-app.yml
```

## Integration with CI/CD

Example GitHub Actions workflow:

```yaml
name: Deploy to Azure IaaS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Ansible
        run: |
          pip install ansible
          ansible-galaxy collection install azure.azcollection
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Application
        run: |
          cd ansible
          ansible-playbook -i inventory/azure_rm.yml playbooks/deploy-app.yml
```

## Best Practices

1. **Idempotency**: All tasks are idempotent - safe to run multiple times
2. **Testing**: Test playbooks in dev before running in production
3. **Version Control**: Keep playbooks and roles in version control
4. **Documentation**: Document custom variables and modifications
5. **Monitoring**: Check Ansible output for errors and warnings

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Azure Ansible Collection](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/)
- [Docker Module Documentation](https://docs.ansible.com/ansible/latest/collections/community/docker/)
- [IaaS Deployment Guide](../docs/deployment-iaas.md)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Ansible logs with `-vvv` flag
3. Check Azure Portal for VM status
4. Refer to the main deployment guide: `docs/deployment-iaas.md`

