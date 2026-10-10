#!/usr/bin/env python3
"""Explicit style check/fix for tracked app sources, never packages or secrets."""
import argparse
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--fix', action='store_true', help='Rewrite tracked Swift files explicitly')
args = parser.parse_args()
files = subprocess.check_output(
    ['git', 'ls-files', '-z', '--', 'PictureBookLendingAdminApp/**/*.swift'], cwd=root
).decode().split('\0')
files = [str(root / name) for name in files if name]
command = ['swift', 'format']
command += ['--in-place'] if args.fix else ['lint', '--strict']
command += ['--configuration', str(root / 'PictureBookLendingAdminApp/.swift-format')]
raise SystemExit(subprocess.run(command + files, cwd=root).returncode)
