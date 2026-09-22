#!/usr/bin/env python3
"""Decharge les modeles Ollama actuellement residents. Ne supprime aucun poids."""
import json,urllib.request,subprocess
from pathlib import Path
base='http://127.0.0.1:11434'
try:
    with urllib.request.urlopen(base+'/api/ps',timeout=10) as r:models=json.load(r).get('models',[])
    for model in models:
        name=model.get('name') or model['model']
        root=Path(__file__).resolve().parent.parent
        subprocess.run(['sudo','docker','compose','--project-directory',str(root),'--env-file',str(root/'.env'),'-f',str(root/'compose.yaml'),'exec','-T','ollama','ollama','stop',name],check=True)
        print('Decharge :',name)
except (OSError,ValueError,subprocess.CalledProcessError) as e:
    raise SystemExit(str(e)) from e
