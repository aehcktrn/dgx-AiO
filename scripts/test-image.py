#!/usr/bin/env python3
"""Controle les noeuds charges, soumet une image puis verifie sa presence dans l'historique."""
from __future__ import annotations
import argparse,json,time,urllib.request,urllib.error
from pathlib import Path

def req(base:str,path:str,data=None):
    body=None if data is None else json.dumps(data).encode()
    r=urllib.request.Request(base+path,data=body,headers={'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r,timeout=30) as response:return json.load(response)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f'HTTP {e.code}: {e.read().decode(errors="replace")}') from e

def main()->None:
    p=argparse.ArgumentParser();p.add_argument('--base',default='http://127.0.0.1:8188');p.add_argument('--timeout',type=int,default=900)
    a=p.parse_args();root=Path(__file__).resolve().parent.parent
    flow=json.loads((root/'workflows/z-image-turbo.api.json').read_text())
    catalog=req(a.base,'/object_info')
    for nid,node in flow.items():
        if node['class_type'] not in catalog:raise RuntimeError(f"Noeud absent : {node['class_type']}")
        required=catalog[node['class_type']].get('input',{}).get('required',{})
        for key,spec in required.items():
            if key not in node['inputs']:raise RuntimeError(f'Entree obligatoire absente : {nid}.{key}')
            value=node['inputs'][key]
            if isinstance(spec[0],list) and not isinstance(value,list) and value not in spec[0]:
                raise RuntimeError(f'Valeur non disponible : {nid}.{key}={value!r}')
    reply=req(a.base,'/prompt',{'prompt':flow,'client_id':'dgx-spark-smoke-test'})
    if reply.get('node_errors'):raise RuntimeError(json.dumps(reply['node_errors'],ensure_ascii=False))
    pid=reply.get('prompt_id')
    if not pid:raise RuntimeError(f'Pas de prompt_id : {reply}')
    print(f'Generation soumise : {pid}',flush=True)
    start=time.monotonic()
    while time.monotonic()-start<a.timeout:
        entry=req(a.base,'/history/'+pid).get(pid)
        if entry:
            status=entry.get('status',{})
            if status.get('status_str')=='error':raise RuntimeError(json.dumps(entry,ensure_ascii=False))
            images=[im for output in entry.get('outputs',{}).values() for im in output.get('images',[])]
            if images:
                print(json.dumps({'prompt_id':pid,'elapsed_seconds':round(time.monotonic()-start,2),'images':images},indent=2))
                return
        time.sleep(2)
    raise RuntimeError('Delai de controle depasse. La generation peut continuer ; consulter ComfyUI avant de relancer.')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError) as e:raise SystemExit(str(e)) from e
