#!/usr/bin/env python3
"""
LYVOXA VERSION MANAGER
======================
Advanced version management system with validation, rollback, and automation.

Usage:
    python3 version-manager.py update 1.6.0 Matrix 1.6
    python3 version-manager.py validate
    python3 version-manager.py rollback
    python3 version-manager.py current
"""

import os
import sys
import re
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import argparse

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    PURPLE = '\033[0;35m'
    NC = '\033[0m'  # No Color

class VersionManager:
    def __init__(self, project_root: str = None):
        self.project_root = Path(project_root or os.getcwd())
        self.version_file = self.project_root / "version.toml"
        self.backup_dir = self.project_root / ".version-backups"
        self.backup_dir.mkdir(exist_ok=True)
        
        # File patterns for version updates
        self.file_patterns = {
            "Cargo.toml": [
                (r'^version = "([^"]+)"', r'version = "{version}"')
            ],
            "README.md": [
                (r'\*\*Current Version\*\*: [^(]+\(v[^)]+\)', 
                 r'**Current Version**: {release_name} {release_number} (v{version})'),
                (r'stellar-1\.5', r'{release_tag}'),
                (r'Stellar 1\.5', r'{release_name} {release_number}')
            ],
            "CHANGELOG.md": [
                (r'## \[1\.5\.0\]', r'## [{version}]'),
                (r'v1\.5\.0', r'v{version}'),
                (r'Stellar Edition', r'{release_name} Edition')
            ],
            "SECURITY.md": [
                (r'stellar-1\.5', r'{release_tag}'),
                (r'Stellar 1\.5', r'{release_name} {release_number}')
            ],
            "Dockerfile": [
                (r'# Version: [^\n]+', r'# Version: {release_name} {release_number}'),
                (r'version="[^"]+"', r'version="{release_tag}"'),
                (r'stellar-1\.5', r'{release_tag}')
            ],
            "docker-compose.yml": [
                (r'# Version: [^\n]+', r'# Version: {release_name} {release_number}'),
                (r'lyvoxa:stellar-1\.5', r'lyvoxa:{release_tag}')
            ],
            "Makefile": [
                (r'# Version: [^\n]+', r'# Version: {release_name} {release_number}')
            ],
            "build.sh": [
                (r'# Version: [^\n]+', r'# Version: {release_name} {release_number}'),
                (r'Lyvoxa Build Script - [^"]+', r'Lyvoxa Build Script - {release_name} {release_number}')
            ],
            ".github/workflows/ci.yml": [
                (r'# Version: [^\n]+', r'# Version: {release_name} {release_number}'),
                (r'stellar-1\.5', r'{release_tag}')
            ],
            ".github/workflows/release.yml": [
                (r'# Version: [^\n]+', r'# Version: {release_name} {release_number}'),
                (r"default: 'stellar-1\.5'", r"default: '{release_tag}'")
            ],
            "docs/SETUP_SSH_SIGNING.md": [
                (r'stellar-1\.5', r'{release_tag}')
            ]
        }
    
    def log(self, level: str, message: str):
        """Colored logging"""
        color_map = {
            'INFO': Colors.BLUE,
            'SUCCESS': Colors.GREEN,
            'WARNING': Colors.YELLOW,
            'ERROR': Colors.RED,
            'HEADER': Colors.CYAN
        }
        color = color_map.get(level, Colors.NC)
        print(f"{color}[{level}]{Colors.NC} {message}")
    
    def parse_version_toml(self) -> Dict[str, str]:
        """Parse version.toml file"""
        if not self.version_file.exists():
            raise FileNotFoundError(f"Version file not found: {self.version_file}")
        
        content = self.version_file.read_text()
        version_data = {}
        
        # Simple TOML parsing for our specific format
        patterns = {
            'semantic': r'semantic = "([^"]+)"',
            'release_name': r'release_name = "([^"]+)"',
            'release_number': r'release_number = "([^"]+)"',
            'release_tag': r'release_tag = "([^"]+)"'
        }
        
        for key, pattern in patterns.items():
            match = re.search(pattern, content)
            if match:
                version_data[key] = match.group(1)
        
        return version_data
    
    def validate_version(self, version: str) -> bool:
        """Validate semantic version format"""
        pattern = r'^\d+\.\d+\.\d+$'
        return bool(re.match(pattern, version))
    
    def create_backup(self) -> str:
        """Create backup of current state"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = self.backup_dir / f"backup_{timestamp}"
        backup_path.mkdir()
        
        # Backup all files that will be modified
        for filename in self.file_patterns.keys():
            file_path = self.project_root / filename
            if file_path.exists():
                shutil.copy2(file_path, backup_path / filename)
        
        # Backup version.toml
        if self.version_file.exists():
            shutil.copy2(self.version_file, backup_path / "version.toml")
        
        self.log("SUCCESS", f"Backup created: {backup_path}")
        return str(backup_path)
    
    def update_version_toml(self, version: str, release_name: str, release_number: str):
        """Update version.toml file"""
        release_tag = f"{release_name.lower()}-{release_number}"
        
        content = self.version_file.read_text()
        
        # Update each field
        content = re.sub(r'semantic = "[^"]+"', f'semantic = "{version}"', content)
        content = re.sub(r'release_name = "[^"]+"', f'release_name = "{release_name}"', content)
        content = re.sub(r'release_number = "[^"]+"', f'release_number = "{release_number}"', content)
        content = re.sub(r'release_tag = "[^"]+"', f'release_tag = "{release_tag}"', content)
        
        self.version_file.write_text(content)
        self.log("SUCCESS", "Version configuration updated")
    
    def update_files(self, version_data: Dict[str, str]) -> List[str]:
        """Update all project files with new version"""
        updated_files = []
        
        for filename, patterns in self.file_patterns.items():
            file_path = self.project_root / filename
            
            if not file_path.exists():
                self.log("WARNING", f"File not found: {filename}")
                continue
            
            content = file_path.read_text()
            original_content = content
            
            # Apply all patterns for this file
            for pattern, replacement in patterns:
                # Format replacement string with version data
                formatted_replacement = replacement.format(**version_data)
                content = re.sub(pattern, formatted_replacement, content)
            
            # Only write if content changed
            if content != original_content:
                file_path.write_text(content)
                updated_files.append(filename)
                self.log("SUCCESS", f"✅ {filename} updated")
            else:
                self.log("INFO", f"⏭️  {filename} (no changes needed)")
        
        return updated_files
    
    def add_changelog_entry(self, version: str, release_name: str, release_number: str):
        """Add new entry to CHANGELOG.md"""
        changelog_path = self.project_root / "CHANGELOG.md"
        if not changelog_path.exists():
            return
        
        content = changelog_path.read_text()
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        new_entry = f"""
## [{version}] - {release_name} Edition - {current_date}

### 🌟 Major Features
- New features will be documented here

### 🔧 Improvements
- Performance optimizations and bug fixes

### 📚 Documentation
- Updated documentation and examples

"""
        
        # Insert after [Unreleased] section
        content = re.sub(
            r'(## \[Unreleased\]\n)',
            r'\1' + new_entry,
            content
        )
        
        changelog_path.write_text(content)
        self.log("SUCCESS", "✅ CHANGELOG.md entry added")
    
    def validate_project(self) -> bool:
        """Validate project state after version update"""
        self.log("INFO", "Validating project state...")
        
        try:
            # Test Cargo.toml syntax
            result = subprocess.run(['cargo', 'check', '--quiet'], 
                                  cwd=self.project_root, 
                                  capture_output=True, text=True)
            if result.returncode != 0:
                self.log("ERROR", f"Cargo validation failed: {result.stderr}")
                return False
            
            # Check if all expected files exist
            for filename in self.file_patterns.keys():
                file_path = self.project_root / filename
                if file_path.exists() and filename.endswith('.toml'):
                    # Basic TOML syntax check
                    try:
                        content = file_path.read_text()
                        # Simple validation - check for balanced quotes
                        if content.count('"') % 2 != 0:
                            self.log("ERROR", f"Syntax error in {filename}")
                            return False
                    except Exception as e:
                        self.log("ERROR", f"Error reading {filename}: {e}")
                        return False
            
            self.log("SUCCESS", "Project validation passed")
            return True
            
        except Exception as e:
            self.log("ERROR", f"Validation error: {e}")
            return False
    
    def rollback(self, backup_path: str = None) -> bool:
        """Rollback to previous version"""
        if not backup_path:
            # Find latest backup
            backups = sorted(self.backup_dir.glob("backup_*"))
            if not backups:
                self.log("ERROR", "No backups found")
                return False
            backup_path = backups[-1]
        
        backup_dir = Path(backup_path)
        if not backup_dir.exists():
            self.log("ERROR", f"Backup not found: {backup_path}")
            return False
        
        self.log("INFO", f"Rolling back from: {backup_dir}")
        
        # Restore all files
        for backup_file in backup_dir.iterdir():
            target_file = self.project_root / backup_file.name
            shutil.copy2(backup_file, target_file)
            self.log("SUCCESS", f"✅ Restored {backup_file.name}")
        
        self.log("SUCCESS", "Rollback completed")
        return True
    
    def get_current_version(self) -> Dict[str, str]:
        """Get current version information"""
        try:
            return self.parse_version_toml()
        except Exception as e:
            self.log("ERROR", f"Error reading version: {e}")
            return {}
    
    def update_version(self, version: str, release_name: str, release_number: str) -> bool:
        """Main version update function"""
        # Validation
        if not self.validate_version(version):
            self.log("ERROR", f"Invalid version format: {version}")
            return False
        
        current_version = self.get_current_version()
        if not current_version:
            return False
        
        self.log("HEADER", "🚀 LYVOXA VERSION UPDATE")
        self.log("INFO", f"Current: {current_version.get('semantic', 'unknown')} "
                        f"({current_version.get('release_name', 'unknown')} "
                        f"{current_version.get('release_number', 'unknown')})")
        self.log("INFO", f"New: {version} ({release_name} {release_number})")
        
        # Create backup
        backup_path = self.create_backup()
        
        try:
            # Update version.toml
            self.update_version_toml(version, release_name, release_number)
            
            # Prepare version data
            version_data = {
                'version': version,
                'release_name': release_name,
                'release_number': release_number,
                'release_tag': f"{release_name.lower()}-{release_number}"
            }
            
            # Update all files
            updated_files = self.update_files(version_data)
            
            # Add changelog entry
            self.add_changelog_entry(version, release_name, release_number)
            
            # Validate
            if not self.validate_project():
                self.log("ERROR", "Validation failed, rolling back...")
                self.rollback(backup_path)
                return False
            
            self.log("HEADER", "🎉 VERSION UPDATE COMPLETE!")
            self.log("SUCCESS", f"Updated {len(updated_files)} files")
            self.log("INFO", f"Backup available at: {backup_path}")
            
            # Show next steps
            release_tag = version_data['release_tag']
            print(f"\n{Colors.CYAN}Next steps:{Colors.NC}")
            print(f"  1. Review: git diff")
            print(f"  2. Test: ./build.sh release")
            print(f"  3. Commit: git add . && git commit -m 'bump: version {version} ({release_name} {release_number})'")
            print(f"  4. Tag: git tag -a {release_tag} -m '{release_name} {release_number} Release'")
            print(f"  5. Push: git push origin main && git push origin {release_tag}")
            
            return True
            
        except Exception as e:
            self.log("ERROR", f"Update failed: {e}")
            self.log("INFO", "Rolling back...")
            self.rollback(backup_path)
            return False

def main():
    parser = argparse.ArgumentParser(description="Lyvoxa Version Manager")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Update command
    update_parser = subparsers.add_parser('update', help='Update version')
    update_parser.add_argument('version', help='Semantic version (e.g., 1.6.0)')
    update_parser.add_argument('release_name', help='Release name (e.g., Matrix)')
    update_parser.add_argument('release_number', help='Release number (e.g., 1.6)')
    
    # Other commands
    subparsers.add_parser('current', help='Show current version')
    subparsers.add_parser('validate', help='Validate project state')
    subparsers.add_parser('rollback', help='Rollback to latest backup')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    vm = VersionManager()
    
    if args.command == 'update':
        success = vm.update_version(args.version, args.release_name, args.release_number)
        sys.exit(0 if success else 1)
    
    elif args.command == 'current':
        version_data = vm.get_current_version()
        if version_data:
            vm.log("INFO", f"Current version: {version_data.get('semantic', 'unknown')} "
                          f"({version_data.get('release_name', 'unknown')} "
                          f"{version_data.get('release_number', 'unknown')})")
        sys.exit(0)
    
    elif args.command == 'validate':
        success = vm.validate_project()
        sys.exit(0 if success else 1)
    
    elif args.command == 'rollback':
        success = vm.rollback()
        sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
