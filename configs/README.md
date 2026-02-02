# Environment Configuration Guide

This directory contains YAML configuration files for each environment, used by the rendering system to generate Docker Compose and Nginx configuration files from Jinja2 templates.

## Configuration Files

- `staging.yaml` - Staging environment configuration
- `production.yaml` - Production environment configuration
- `dev.yaml` - Development environment configuration

## Config File Format

Each YAML file should contain:

```yaml
# Environment name
environment: staging

# Domain name for SSL certificates and nginx configuration
domainName: your-domain.com

# Email for Let's Encrypt certificate registration
letsencryptEmail: your-email@example.com
```

### Fields

- **environment**: The environment name (staging, production, dev, etc.)
- **domainName**: The domain name for SSL certificates and nginx configuration
- **letsencryptEmail**: Email address for Let's Encrypt certificate registration

## Template System

Templates use **Jinja2** syntax (same as Terraform templates), allowing for:

- Simple variable substitution: `{{ variable_name }}`
- Filters: `{{ variable_name | upper }}`
- Conditionals and loops for advanced use cases

## Usage

### Render a single environment from config:

```powershell
.\scripts\render.ps1 -ConfigFile ./configs/staging.yaml
```

### Render all environments automatically:

```powershell
.\scripts\render-all.ps1
```

## Adding New Variables

To add new variables to your templates:

1. Add the field to your YAML config file:

   ```yaml
   environment: staging
   domainName: terraform.martinn.no
   letsencryptEmail: m4rtini89@gmail.com
   apiPort: 3000
   ```

2. Update your template to use it:

   ```jinja2
   expose:
     - "{{ apiPort }}"
   ```

3. Re-render:
   ```powershell
   .\scripts\render-all.ps1
   ```

No script changes needed!

## Dependencies

The rendering system requires:

- **Python 3** (with Jinja2 and PyYAML packages)
- These are automatically installed on first run

## Updating Configurations

1. Edit the appropriate YAML file in this directory
2. Run the render script to regenerate the environment configurations
3. Commit the updated YAML files to git
4. The rendered files in `../rendered/` will be regenerated (these may or may not be committed based on your workflow)

## Security Notes

- These config files are committed to git and should only contain non-sensitive configuration
- API tokens, certificates, and other secrets should NOT be stored here
- Consider using `.gitignore` if you need to store sensitive values locally without committing them
