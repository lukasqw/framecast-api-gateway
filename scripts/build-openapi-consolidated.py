#!/usr/bin/env python3
"""
Build consolidated OpenAPI specification from base and path files.
Merges openapi/base.json with all files in openapi/paths/ directory.
"""

import json
import os
from pathlib import Path


def load_json(filepath):
    """Load and parse JSON file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_json(data, filepath):
    """Save data as formatted JSON file."""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')


def merge_paths(base_spec, paths_dir):
    """Merge all path files into the base specification."""
    spec = base_spec.copy()
    spec['paths'] = {}
    
    # Get all JSON files in paths directory
    paths_dir = Path(paths_dir)
    if not paths_dir.exists():
        print(f"Warning: Paths directory not found: {paths_dir}")
        return spec
    
    path_files = sorted(paths_dir.glob('*.json'))
    
    for path_file in path_files:
        print(f"Processing: {path_file.name}")
        try:
            paths_data = load_json(path_file)
            # Merge paths from this file
            spec['paths'].update(paths_data)
        except Exception as e:
            print(f"Error processing {path_file.name}: {e}")
            raise
    
    return spec


def main():
    """Main execution function."""
    # Define paths
    base_file = 'openapi/base.json'
    paths_dir = 'openapi/paths'
    output_file = 'openapi-spec.json'
    
    print("Building consolidated OpenAPI specification...")
    print(f"Base file: {base_file}")
    print(f"Paths directory: {paths_dir}")
    print(f"Output file: {output_file}")
    print()
    
    # Load base specification
    try:
        base_spec = load_json(base_file)
        print(f"✓ Loaded base specification")
    except FileNotFoundError:
        print(f"Error: Base file not found: {base_file}")
        exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in base file: {e}")
        exit(1)
    
    # Merge path files
    try:
        consolidated_spec = merge_paths(base_spec, paths_dir)
        path_count = len(consolidated_spec.get('paths', {}))
        print(f"✓ Merged {path_count} paths")
    except Exception as e:
        print(f"Error merging paths: {e}")
        exit(1)
    
    # Save consolidated specification
    try:
        save_json(consolidated_spec, output_file)
        print(f"✓ Saved consolidated spec to {output_file}")
    except Exception as e:
        print(f"Error saving output file: {e}")
        exit(1)
    
    print()
    print("✓ OpenAPI specification built successfully!")


if __name__ == '__main__':
    main()