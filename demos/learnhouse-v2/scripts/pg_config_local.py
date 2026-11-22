#!/usr/bin/env python3
"""Map the extracted distro pg_config paths into the private sysroot."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SYSROOT = ROOT / '.runtime' / 'sysroot'
output = subprocess.check_output([str(SYSROOT / 'usr/bin/pg_config'), *sys.argv[1:]], text=True)
if len(sys.argv) == 2 and sys.argv[1] in {
    '--bindir', '--docdir', '--htmldir', '--includedir', '--pkgincludedir',
    '--includedir-server', '--libdir', '--pkglibdir', '--localedir',
    '--mandir', '--sharedir', '--sysconfdir', '--pgxs',
}:
    output = str(SYSROOT) + output
sys.stdout.write(output)
