#!/usr/bin/env python3
"""Check that the app and widget inherit one version source. No credentials needed."""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
project = root / 'PictureBookLendingAdminApp/PictureBookLendingAdmin.xcodeproj/project.pbxproj'
objects = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(project)]))['objects']
project_object = next(obj for obj in objects.values() if obj.get('isa') == 'PBXProject')
configurations = objects[project_object['buildConfigurationList']]['buildConfigurations']
versions = [objects[key]['buildSettings'].get('CURRENT_PROJECT_VERSION') for key in configurations]
if not versions or not all(versions) or len(set(versions)) != 1:
    raise SystemExit('Project Debug/Release must share CURRENT_PROJECT_VERSION')
for obj in objects.values():
    if obj.get('isa') != 'PBXNativeTarget':
        continue
    if obj.get('productType') not in ['com.apple.product-type.application', 'com.apple.product-type.app-extension']:
        continue
    for key in objects[obj['buildConfigurationList']]['buildConfigurations']:
        config = objects[key]
        if 'CURRENT_PROJECT_VERSION' in config['buildSettings']:
            raise SystemExit(f"{obj['name']} {config['name']}: inherit CURRENT_PROJECT_VERSION from project")
print(f'App/widget version inheritance valid (project version {versions[0]}).')
