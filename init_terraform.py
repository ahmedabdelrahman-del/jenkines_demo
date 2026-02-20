#!/usr/bin/env python3
import subprocess
import os

os.chdir('/workspaces/jenkines_demo/aws_eks_terraform')
result = subprocess.run(['terraform', 'init'], capture_output=True, text=True)
print(result.stdout)
print(result.stderr)
print(f"Return code: {result.returncode}")
