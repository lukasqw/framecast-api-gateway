#!/usr/bin/env python3
"""
Build OpenAPI Specification from modular JSON files.

This script consolidates multiple JSON files from the openapi/ directory
into a single openapi-spec.json file.

Structure:
  openapi/
    ├── base.json              # Base configuration (info, servers, components)
    └── paths/                 # Path definitions by module
        ├── auth.json
        ├── users.json
        ├── customers.json
        ├── vehicles.json
        ├── services.json
        ├── products.json
        ├── inventory.json
        └── service-orders.json

Usage:
  python3 scripts/build-openapi.py
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Any

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    END = '\033[0m'

def log_info(message: str):
    print(f"{Colors.BLUE}ℹ{Colors.END} {message}")

def log_success(message: str):
    print(f"{Colors.GREEN}✓{Colors.END} {message}")

def log_warning(message: str):
    print(f"{Colors.YELLOW}⚠{Colors.END} {message}")

def log_error(message: str):
    print(f"{Colors.RED}✗{Colors.END} {message}")

def load_json_file(file_path: Path) -> Dict[str, Any]:
    """Load and parse a JSON file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        log_error(f"Invalid JSON in {file_path}: {e}")
        sys.exit(1)
    except Exception as e:
        log_error(f"Error reading {file_path}: {e}")
        sys.exit(1)

def merge_paths(paths_dir: Path) -> Dict[str, Any]:
    """Merge all path definition files from the paths directory."""
    merged_paths = {}
    
    if not paths_dir.exists():
        log_error(f"Paths directory not found: {paths_dir}")
        sys.exit(1)
    
    # Get all JSON files in paths directory
    path_files = sorted(paths_dir.glob('*.json'))
    
    if not path_files:
        log_warning(f"No path files found in {paths_dir}")
        return merged_paths
    
    log_info(f"Found {len(path_files)} path definition files")
    
    for path_file in path_files:
        log_info(f"  Loading {path_file.name}...")
        paths_data = load_json_file(path_file)
        
        # Count endpoints in this file
        endpoint_count = sum(
            len([m for m in methods.keys() if m != 'parameters'])
            for methods in paths_data.values()
        )
        
        # Merge paths
        for path, methods in paths_data.items():
            if path in merged_paths:
                log_warning(f"    Path {path} already exists, merging methods...")
                merged_paths[path].update(methods)
            else:
                merged_paths[path] = methods
        
        log_success(f"    Added {endpoint_count} endpoint(s) from {path_file.name}")
    
    return merged_paths

def build_openapi_spec(openapi_dir: Path, output_file: Path):
    """Build the complete OpenAPI specification."""
    log_info("Building OpenAPI specification...")
    
    # Load base configuration
    base_file = openapi_dir / 'base.json'
    if not base_file.exists():
        log_error(f"Base configuration not found: {base_file}")
        sys.exit(1)
    
    log_info("Loading base configuration...")
    spec = load_json_file(base_file)
    log_success("Base configuration loaded")
    
    # Merge path definitions
    paths_dir = openapi_dir / 'paths'
    log_info("Merging path definitions...")
    spec['paths'] = merge_paths(paths_dir)
    
    # Count total endpoints
    total_endpoints = sum(
        len([m for m in methods.keys() if m != 'parameters'])
        for methods in spec['paths'].values()
    )
    log_success(f"Merged {len(spec['paths'])} paths with {total_endpoints} endpoints")
    
    # Write output file
    log_info(f"Writing to {output_file}...")
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(spec, f, indent=2, ensure_ascii=False)
        log_success(f"OpenAPI specification written to {output_file}")
    except Exception as e:
        log_error(f"Error writing output file: {e}")
        sys.exit(1)
    
    # Validate JSON
    log_info("Validating generated JSON...")
    try:
        with open(output_file, 'r', encoding='utf-8') as f:
            json.load(f)
        log_success("Generated JSON is valid")
    except json.JSONDecodeError as e:
        log_error(f"Generated JSON is invalid: {e}")
        sys.exit(1)
    
    # Print summary
    print()
    print("=" * 60)
    print(f"{Colors.GREEN}OpenAPI Specification Built Successfully!{Colors.END}")
    print("=" * 60)
    print(f"Output file:      {output_file}")
    print(f"Total paths:      {len(spec['paths'])}")
    print(f"Total endpoints:  {total_endpoints}")
    print(f"File size:        {output_file.stat().st_size:,} bytes")
    print("=" * 60)

def main():
    """Main entry point."""
    # Determine project root (parent of scripts directory)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Define paths
    openapi_dir = project_root / 'openapi'
    output_file = project_root / 'openapi-spec.json'
    
    print()
    print("=" * 60)
    print(f"{Colors.BLUE}OpenAPI Builder{Colors.END}")
    print("=" * 60)
    print(f"Project root:  {project_root}")
    print(f"OpenAPI dir:   {openapi_dir}")
    print(f"Output file:   {output_file}")
    print("=" * 60)
    print()
    
    # Build specification
    build_openapi_spec(openapi_dir, output_file)
    
    print()
    log_success("Done!")
    print()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print()
        log_warning("Build cancelled by user")
        sys.exit(1)
    except Exception as e:
        print()
        log_error(f"Unexpected error: {e}")
        sys.exit(1)
