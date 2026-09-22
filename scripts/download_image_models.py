#!/usr/bin/env python3
"""Telecharge uniquement trois fichiers de poids ; fige la revision et verifie les SHA-256 LFS."""
from __future__ import annotations
import hashlib,json,os,shutil,sys
from pathlib import Path
from huggingface_hub import HfApi,hf_hub_download

def digest(path:Path)->str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(8*1024*1024),b''):h.update(block)
    return h.hexdigest()

def main()->None:
    if len(sys.argv)!=2:raise SystemExit('Usage: download_image_models.py /srv/dgx-ai/comfy')
    base=Path(sys.argv[1]).resolve()
    repo='Comfy-Org/z_image_turbo'
    paths=['split_files/diffusion_models/z_image_turbo_bf16.safetensors',
           'split_files/text_encoders/qwen_3_4b.safetensors',
           'split_files/vae/ae.safetensors']
    manifest_path=base/'image-models.json'
    old=json.loads(manifest_path.read_text()) if manifest_path.exists() else None
    info=HfApi().model_info(repo, revision=old['revision'] if old else None,files_metadata=True)
    revision=info.sha
    if not revision:raise SystemExit('Revision du depot introuvable.')
    siblings={x.rfilename:x for x in info.siblings}
    entries=[]
    for rel in paths:
        item=siblings.get(rel)
        lfs=getattr(item,'lfs',None)
        expected=getattr(lfs,'sha256',None) if lfs is not None else None
        if expected is None and isinstance(lfs,dict):expected=lfs.get('sha256')
        if not expected:raise SystemExit(f'SHA-256 amont absent : {rel}. Arret, verification manuelle requise.')
        target=base/'ComfyUI'/'models'/Path(rel).relative_to('split_files')
        target.parent.mkdir(parents=True,exist_ok=True)
        if target.exists():
            if digest(target)!=expected:raise SystemExit(f'Fichier existant different : {target}. Ne pas ecraser sans examen.')
            print(f'Deja verifie : {target.name}',flush=True)
        else:
            staged=Path(hf_hub_download(repo_id=repo,filename=rel,revision=revision,local_dir=str(base/'staging')))
            if digest(staged)!=expected:raise SystemExit(f'Empreinte incorrecte : {staged}')
            shutil.move(str(staged),str(target))
            print(f'Telecharge et verifie : {target.name}',flush=True)
        entries.append({'repository_path':rel,'local_path':str(target.relative_to(base)),
                        'size_bytes':target.stat().st_size,'sha256':expected})
        tmp=manifest_path.with_suffix('.json.tmp')
        tmp.write_text(json.dumps({'repository':repo,'revision':revision,'files':entries},indent=2)+'\n')
        os.replace(tmp,manifest_path)
    print(f'Revision figee : {revision}')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError) as e:raise SystemExit(str(e)) from e
