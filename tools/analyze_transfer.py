"""Locked paired comparison for actual companion transfer experiments."""
import argparse,json,statistics,hashlib
from pathlib import Path

def read(p):
    return json.loads(Path(p).read_text(encoding='utf-8-sig'))

def compare(batch,rules):
    base=read(batch/'baseline/summary.json')
    key=lambda row:(row['scenario'],row['strategy'],row['seed'])
    baseline={key(row):row for row in base['rows']}
    outputs={}
    for summary in sorted(batch.glob('*/summary.json')):
        if summary.parent.name=='baseline':continue
        rows={key(row):row for row in read(summary)['rows']}
        if baseline.keys()!=rows.keys():raise ValueError('Mismatched trial matrix')
        pairs=[];hard=[]
        for k,b in baseline.items():
            c=rows[k]
            for r in [b,c]:
                if r['source_id']!=b['source_id'] or r['evaluation_version']!=b['evaluation_version']:raise ValueError('Changed source/evaluation')
                if r['build_ids']!=rules['build_ids']:raise ValueError('Different build')
                if abs(r['applied']['transfer_retention']-r['profile']['transfer_retention'])>1e-7:raise ValueError('Candidate not actually applied')
                if r['applied']['impulse']!=1050 or r['applied']['cooldown']!=2.2 or r['applied']['opposing_cancel']!=0:raise ValueError('Unrelated factor changed')
                invalid=r['hard_failures'] or r['longest_chain']>3 or r['physics_hz']!=120 or r['time_scale']!=1 or abs(r['seconds']-20)>.02 or r['partner_direct_damage']>r['effective_damage']
                if invalid:hard.append({'trial':k,'profile':r['profile']['id'],'failures':r['hard_failures'] or ['contract_failure']})
            bt=b['clear_time'] if b['clear_time']>=0 else b['seconds']
            ct=c['clear_time'] if c['clear_time']>=0 else c['seconds']
            pairs.append({'trial':k,'relative_change':(ct-bt)/max(bt,1/120),'baseline_clear':bt,'candidate_clear':ct,'hp_change':c['hp_lost']-b['hp_lost']})
        target_scenario=rules.get('partner_target_scenario','relay')
        target_base=[r for r in baseline.values() if r['scenario']==target_scenario]
        target_rows=[r for r in rows.values() if r['scenario']==target_scenario]
        rate=lambda group:sum(r['partner_direct_damage'] for r in group)/max(sum(r['threat_seconds'] for r in group),1/120)
        br,cr=rate(target_base),rate(target_rows)
        rate_change=(cr-br)/br if br>0 else (None if cr==0 else 'from_zero')
        sel=rules['selection'];mean=statistics.mean(x['relative_change'] for x in pairs);worst=max(x['relative_change'] for x in pairs);hp=sum(x['hp_change'] for x in pairs)
        gates={'clear_improved':mean<=-sel['required_mean_paired_clear_time_improvement'],'relay_direct_hp_rate_improved':br>0 and cr>=br*(1+sel['required_relay_partner_direct_damage_per_threat_second_improvement']),'worst_bounded':worst<=sel['max_worst_paired_clear_time_regression'],'no_extra_hp_loss':hp<=sel['max_total_hp_loss_increase'],'no_physics_failure':not hard}
        outputs[summary.parent.name]={'mean_paired_clear_change':mean,'worst_paired_clear_regression':worst,'hp_loss_change':hp,'relay_direct_hp_rate_baseline':br,'relay_direct_hp_rate_candidate':cr,'relay_rate_change':rate_change,'gates':gates,'short_gates_pass':all(gates.values()),'hard_failures':hard,'worst_cases':sorted(pairs,key=lambda p:p['relative_change'],reverse=True)[:8],'by_scenario':{s:{'mean_relative_clear_change':statistics.mean(p['relative_change'] for p in pairs if p['trial'][0]==s),'baseline_partner_hp':sum(r['partner_direct_damage'] for r in baseline.values() if r['scenario']==s),'candidate_partner_hp':sum(r['partner_direct_damage'] for r in rows.values() if r['scenario']==s),'baseline_activations':sum(r['activations'] for r in baseline.values() if r['scenario']==s),'candidate_activations':sum(r['activations'] for r in rows.values() if r['scenario']==s)} for s in rules['scenarios']}}
    return {'rules_version':rules['version'],'baseline_trials':len(baseline),'source_id':next(iter(baseline.values()))['source_id'],'candidates':outputs,'note':'Preselected legal fixture build; same inputs/seeds. No natural-run victory or user approval implied.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('batch',type=Path);parser.add_argument('--rules',type=Path,default=Path(__file__).resolve().parents[1]/'resources/roguelite/balance/transfer_rules_v1.json');args=parser.parse_args()
    result=compare(args.batch,read(args.rules));result['rules_sha256']=hashlib.sha256(args.rules.read_bytes()).hexdigest()
    (args.batch/'comparison.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    for name,r in result['candidates'].items():print(name,'mean=',round(r['mean_paired_clear_change'],4),'worst=',round(r['worst_paired_clear_regression'],4),'relay_rate=',r['relay_rate_change'],'hp=',r['hp_loss_change'],'gates=',r['gates'])
