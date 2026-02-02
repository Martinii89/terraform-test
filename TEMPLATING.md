# Jinja2 Templating System

Your environment rendering system now uses **Jinja2**, the same templating engine used by Terraform and Ansible.

## How It Works

1. **YAML Config Files** - Store environment-specific values in `configs/`
2. **Jinja2 Templates** - Use `{{ variable }}` syntax in template files (`.tpl`)
3. **Python Rendering** - Renders templates with config values

## Quick Start

### Render all environments:

```powershell
.\scripts\render-all.ps1
```

### Render a single environment:

```powershell
.\scripts\render.ps1 -ConfigFile ./configs/staging.yaml
```

## Adding New Variables

To add a new variable to your configuration:

1. Add it to your config file (`configs/staging.yaml`):

   ```yaml
   environment: staging
   domainName: terraform.martinn.no
   letsencryptEmail: m4rtini89@gmail.com
   apiTimeout: 30 # New variable
   ```

2. Use it in your template (`templates/infra/docker-compose.yaml.tpl`):

   ```jinja2
   environment:
     - API_TIMEOUT={{ apiTimeout }}
   ```

3. Re-render:
   ```powershell
   .\scripts\render-all.ps1
   ```

## Template Features

Jinja2 supports much more than simple variable substitution:

### Variables

```jinja2
{{ domainName }}
```

### Filters

```jinja2
{{ domainName | upper }}      # TERRAFORM.MARTINN.NO
{{ domainName | lower }}      # terraform.martinn.no
```

### Conditionals

```jinja2
{% if environment == 'production' %}
  # Production-specific config
{% endif %}
```

### Loops

```jinja2
{% for port in ports %}
  - "{{ port }}/tcp"
{% endfor %}
```

## File Types

- **Template files** (`.tpl`): Processed through Jinja2, extension removed in output
- **Static files**: Copied as-is without processing

Examples:

- `docker-compose.yaml.tpl` → `docker-compose.yaml` (rendered)
- `nginx/nginx.conf` → `nginx/nginx.conf` (copied)

## Dependencies

Python packages automatically installed on first run:

- `jinja2` - Template engine
- `pyyaml` - YAML configuration parser

## Why Jinja2?

✓ **Same syntax as Terraform** - Familiar if you already use Terraform  
✓ **Industry standard** - Used by Ansible, Kubernetes, Docker, etc.  
✓ **Scalable** - Add variables without changing the engine  
✓ **Powerful** - Supports conditionals, loops, filters for complex use cases  
✓ **Well-documented** - Large community and extensive documentation
