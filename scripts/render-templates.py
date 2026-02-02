#!/usr/bin/env python3
"""
Render Jinja2 templates with configuration values.
Usage: python3 render-templates.py <config-file> <templates-dir> <output-dir>
"""

import sys
import json
import os
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, StrictUndefined

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 render-templates.py <config-file> <templates-dir> <output-dir>")
        print("Example: python3 render-templates.py configs/staging.yaml templates/infra rendered/staging")
        sys.exit(1)
    
    config_file = sys.argv[1]
    templates_dir = sys.argv[2]
    output_dir = sys.argv[3]
    
    # Check if config file exists
    if not os.path.exists(config_file):
        print(f"Error: Config file not found: {config_file}", file=sys.stderr)
        sys.exit(1)
    
    # Parse YAML config
    try:
        import yaml
    except ImportError:
        print("Error: PyYAML not installed. Run: pip install PyYAML jinja2", file=sys.stderr)
        sys.exit(1)
    
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    if not config:
        print(f"Error: Config file is empty or invalid: {config_file}", file=sys.stderr)
        sys.exit(1)
    
    # Clean output directory if it exists
    import shutil
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
        print(f"Cleaned existing output directory: {output_dir}")
    
    # Create output directory
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # Set up Jinja2 environment
    env = Environment(
        loader=FileSystemLoader(templates_dir),
        undefined=StrictUndefined
    )
    
    # Process all files in templates directory
    templates_path = Path(templates_dir)
    for template_file in templates_path.rglob('*'):
        if template_file.is_file():
            # Get relative path from templates directory
            relative_path = template_file.relative_to(templates_path)
            
            # Determine if this is a template file (.tpl, .j2, .jinja2)
            is_template = str(relative_path).endswith(('.tpl', '.j2', '.jinja2'))
            
            # Remove template extension if present
            if is_template:
                output_relative_path = Path(str(relative_path).rsplit('.', 1)[0])
            else:
                output_relative_path = relative_path
            
            # Create output file path
            output_file = Path(output_dir) / output_relative_path
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            try:
                if is_template:
                    # Load and render template
                    # Normalize path separators for template loader (Jinja2 uses forward slashes)
                    template_path = str(relative_path).replace('\\', '/')
                    template = env.get_template(template_path)
                    rendered = template.render(config)
                    
                    # Write output file
                    with open(output_file, 'w') as f:
                        f.write(rendered)
                    
                    print(f"✓ Rendered {relative_path} -> {output_relative_path}")
                else:
                    # Copy static files as-is
                    shutil.copy2(template_file, output_file)
                    print(f"✓ Copied {relative_path}")
            except Exception as e:
                print(f"✗ Failed to process {relative_path}: {e}", file=sys.stderr)
                import traceback
                traceback.print_exc(file=sys.stderr)
                sys.exit(1)
    
    print(f"\n✓ All templates rendered successfully to: {output_dir}")

if __name__ == '__main__':
    main()
