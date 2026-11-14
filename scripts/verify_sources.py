#!/usr/bin/env python3
"""Verify reviewed publication files without executing historical project code."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'docs/SOURCE_MANIFEST.json').read_text())
errors = []
seen = set()
changes = {}
for entry in manifest['files']:
    relative = Path(entry['path'])
    if relative.is_absolute() or '..' in relative.parts or str(relative) in seen:
        errors.append(f'Unsafe or duplicate manifest path: {relative}')
        continue
    seen.add(str(relative))
    file = ROOT / relative
    if not file.is_file():
        errors.append(f'Missing source: {relative}')
        continue
    data = file.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != entry['published_sha256'] or len(data) != entry['bytes']:
        errors.append(f'Published hash/size mismatch: {relative}')
    if digest != entry['original_sha256'] and not entry['transformations']:
        errors.append(f'Undocumented publication edit: {relative}')
    for change in entry['transformations']:
        changes[change] = changes.get(change, 0) + 1
    if relative.suffix in {'.a', '.dylib', '.so', '.p12', '.p8', '.pem', '.mobileprovision'}:
        errors.append(f'Excluded binary or signing material: {relative}')
    if 'xcuserdata' in relative.parts or relative.name == 'PointCloud.h':
        errors.append(f'Excluded SDK header or user IDE state: {relative}')
    if re.search(rb'/Users/|/Volumes/|BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY', data):
        errors.append(f'Private path or private-key marker: {relative}')
    if relative.name in {'PointCloudApplication.mm', 'PointCloudApplication.cpp'}:
        if re.search(rb'"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}"', data):
            errors.append(f'Application-key-shaped literal: {relative}')
        if b'REPLACE_WITH_YOUR_POINTCLOUD_APPLICATION_KEY' not in data:
            errors.append(f'Missing application-key placeholder: {relative}')
    if relative.suffix == '.pbxproj':
        for match in re.finditer(rb'(?:"?CODE_SIGN_IDENTITY(?:\[[^\]]+\])?"?|PROVISIONING_PROFILE(?:_SPECIFIER)?|DEVELOPMENT_TEAM)\s*=\s*([^;\r\n]*);', data):
            if match.group(1).strip() != b'""':
                errors.append(f'Nonempty signing setting: {relative}')
    if b'setToRecipients:' in data and re.search(rb'@"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"', data):
        errors.append(f'Hardcoded email recipient: {relative}')

for prefix in [ROOT / 'ios/Scanner', *(ROOT / 'history/ios').glob('*/Scanner'), ROOT / 'history/diskonkey-cpp/Scanner']:
    license_file = prefix / 'LICENSE'
    if not license_file.is_file() or b'Permission is hereby granted' not in license_file.read_bytes():
        errors.append(f'Missing scoped sample MIT notice: {prefix.relative_to(ROOT)}')

result = {'manifest_files': len(seen), 'publication_edit_counts': changes, 'errors': errors,
          'scope': 'Source hashes, exclusion rules, key placeholders, signing settings, paths, and sample license notices; no project code executed.'}
print(json.dumps(result, indent=2))
sys.exit(1 if errors else 0)
