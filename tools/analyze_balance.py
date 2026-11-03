"""Compare paired real-physics candidate trials without inventing human approval."""
import argparse,json,statistics
from pathlib import Path

def load(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

def compare(root, rules):
    base=load(root/'baseline/summary.json')
    key=lambda x:(x['scenario'],x['strategy'],x['seed'])
    baseline={key(x):x for x in base['rows']}
    outputs={}
    for summary in sorted(root.glob('*/summary.json')):
        name=summary.parent.name
        if name=='baseline':continue
        candidate=load(summary); rows={key(x):x for x in candidate['rows']}
        if rows.keys()!=baseline.keys():raise ValueError(f'{name}: mismatched scenarios/strategies/seeds')
        if any(rows[k]['source_id']!=baseline[k]['source_id'] or rows[k]['evaluation_version']!=baseline[k]['evaluation_version'] for k in rows):raise ValueError(f'{name}: source/evaluator changed; rerun all candidates')
        if rules['selection'].get('target_metric')=='first_effective_damage':
            for r in list(rows.values())+list(baseline.values()):
                if r['hard_failures']:raise ValueError('Fix actual physics failures before impulse comparison')
                if r['applied']['impulse']!=r['profile']['impulse'] or r['applied']['opposing_cancel']!=0 or r['applied']['cooldown']!=2.2 or r['applied']['transfer_retention']!=0.85:raise ValueError('Wrong actual candidate or unrelated changed factor')
        pairs=[]
        for k,b in baseline.items():
            c=rows[k]
            bt=b['clear_time'] if b['clear_time']>=0 else b['seconds']
            ct=c['clear_time'] if c['clear_time']>=0 else c['seconds']
            pairs.append({'scenario':k[0],'strategy':k[1],'seed':k[2],'baseline_clear':bt,'candidate_clear':ct,'relative_change':(ct-bt)/max(bt,1/120),'hp_change':c['hp_lost']-b['hp_lost']})
        first_changes=[]
        for k,b in baseline.items():
            c=rows[k];bt=b['first_damage'] if b['first_damage']>=0 else b['seconds'];ct=c['first_damage'] if c['first_damage']>=0 else c['seconds'];first_changes.append((ct-bt)/max(bt,1/120))
        first_change=statistics.mean(first_changes)
        mean=statistics.mean(x['relative_change'] for x in pairs)
        reverse=statistics.mean(x['relative_change'] for x in pairs if x['scenario']=='reverse')
        worst=max(x['relative_change'] for x in pairs)
        hp=sum(x['hp_change'] for x in pairs)
        base_wait=sum(x['cooldown_wait'] for x in baseline.values())
        wait_change=(sum(x['cooldown_wait'] for x in rows.values())-base_wait)/max(base_wait,1/120)
        hard=[{'trial':k,'failures':c['hard_failures']} for k,c in rows.items() if c['hard_failures'] or c['longest_chain']>3 or c['physics_hz']!=120 or c['time_scale']!=1 or abs(c['seconds']-20)>0.02]
        gates={'measured_clear_improvement':mean <= -rules['selection']['required_mean_paired_clear_time_improvement'], 'reverse_improvement':reverse <= -rules['selection']['reverse_clear_or_response_improvement'], 'no_hp_loss_increase':hp<=rules['hard_gates']['max_total_hp_loss_increase'], 'worst_clear_regression_bounded':worst<=rules['selection']['max_worst_paired_clear_time_regression'], 'no_physics_failure':not hard}
        if rules['selection'].get('target_metric')=='total_threat_cooldown_wait':
            del gates['reverse_improvement']
            gates['live_threat_wait_improvement']=wait_change <= -rules['selection']['target_improvement']
        if rules['selection'].get('target_metric')=='first_effective_damage':
            del gates['reverse_improvement']
            gates['first_actual_hp_damage_improved']=first_change<=-rules['selection']['target_improvement']
        outputs[name]={'mean_paired_clear_change':mean,'first_damage_change':first_change,'reverse_clear_change':reverse,'cooldown_wait_change':wait_change,'worst_paired_clear_regression':worst,'hp_loss_change':hp,'gates':gates,'short_fixture_gates_pass':all(gates.values()),'full_run_and_growth_validation':'pending','hard_failures':hard,'worst_cases':sorted(pairs,key=lambda x:x['relative_change'],reverse=True)[:6],'by_scenario':{s:{'baseline_mean_clear':statistics.mean(p['baseline_clear'] for p in pairs if p['scenario']==s),'candidate_mean_clear':statistics.mean(p['candidate_clear'] for p in pairs if p['scenario']==s),'mean_relative_change':statistics.mean(p['relative_change'] for p in pairs if p['scenario']==s),'hp_change':sum(p['hp_change'] for p in pairs if p['scenario']==s)} for s in rules['scenarios']}}
    return {'rules_version':rules['version'],'source_id':base['rows'][0]['source_id'],'baseline_trials':len(baseline),'candidates':outputs,'warning':'Measured fixed-policy evidence; no human play/appearance/sound approval or full-run victory implied.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('batch',type=Path);parser.add_argument('--rules',type=Path,default=Path(__file__).resolve().parents[1]/'resources/roguelite/balance/evaluation_rules_v1.json');args=parser.parse_args()
    report=compare(args.batch,load(args.rules));(args.batch/'comparison.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for name,r in report['candidates'].items():print(name,'paired_clear_change=',round(r['mean_paired_clear_change'],4),'reverse=',round(r['reverse_clear_change'],4),'worst=',round(r['worst_paired_clear_regression'],4),'hp_change=',r['hp_loss_change'],'short_gates=',r['short_fixture_gates_pass'])
