#!/usr/bin/env python3
"""Mesure locale : aucune vitesse predefinie. Les resultats ne sont pas un benchmark cyber."""
from __future__ import annotations
import argparse,json,time,urllib.request
from pathlib import Path

def main()->None:
    p=argparse.ArgumentParser();p.add_argument('--model',default='cyber-reference');p.add_argument('--base',default='http://127.0.0.1:11434');a=p.parse_args()
    payload={'model':a.model,'stream':False,'keep_alive':'2m',
             'prompt':'En francais, explique la difference entre une vulnerabilite, une menace et un risque. Donne un exemple fictif et signale tes hypotheses.',
             'options':{'temperature':0.2,'num_ctx':16384,'num_predict':300,'seed':42}}
    req=urllib.request.Request(a.base.rstrip('/')+'/api/generate',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
    start=time.monotonic()
    with urllib.request.urlopen(req,timeout=900) as r:result=json.load(r)
    if result.get('error'):raise RuntimeError(result['error'])
    duration=result.get('eval_duration',0)/1e9
    metrics={'model':a.model,'wall_seconds':round(time.monotonic()-start,3),
             'load_seconds':result.get('load_duration',0)/1e9,
             'prompt_eval_seconds':result.get('prompt_eval_duration',0)/1e9,
             'eval_count':result.get('eval_count'),
             'generation_tokens_per_second':(result.get('eval_count',0)/duration if duration>0 else None)}
    print(result.get('response',''));print('\n'+json.dumps(metrics,indent=2))
    state=Path(__file__).resolve().parent.parent/'state';state.mkdir(exist_ok=True)
    stamp=time.strftime('%Y%m%d-%H%M%S')
    safe=a.model.replace('/','_').replace(':','_')
    (state/f'test-chat-{safe}-{stamp}.json').write_text(json.dumps({'metrics':metrics,'raw':result},ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError) as e:raise SystemExit(str(e)) from e
