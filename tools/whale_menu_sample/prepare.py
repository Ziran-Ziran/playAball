"""Prepare an isolated native Godot character sample from already downloaded data."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import zipfile

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-archive', required=True, type=Path)
    parser.add_argument('--animation-archive', required=True, type=Path)
    parser.add_argument('--fixture-name', default='whale_menu_3d_final')
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z0-9_]+', args.fixture_name):
        parser.error('fixture-name must be lowercase letters, digits and underscores')
    repo = Path(__file__).resolve().parents[2]
    destination = repo / '.local/art_audio_r2' / args.fixture_name
    if destination.exists():
        parser.error(f'Refusing to overwrite existing fixture: {destination}')
    destination.mkdir(parents=True)
    models = destination / 'models'
    models.mkdir()
    notices = destination / 'notices'
    notices.mkdir()
    with zipfile.ZipFile(args.model_archive) as archive:
        models.joinpath('whale_adult.glb').write_bytes(archive.read('whale-adult/whale-adult.glb'))
        for name in ['README.md','LICENSE','ATTRIBUTION.md','asset.json']:
            notices.joinpath('manny_' + name).write_bytes(archive.read('whale-adult/' + name))
    with zipfile.ZipFile(args.animation_archive) as archive:
        glb = next(name for name in archive.namelist() if name.endswith('/Godot/AnimationLibrary_Godot_Standard.glb'))
        models.joinpath('animations.glb').write_bytes(archive.read(glb))
        notices.joinpath('quaternius_license.txt').write_bytes(archive.read('Animation Library[Standard]/License.txt'))
    source_target = destination / 'sample'
    source_target.mkdir()
    for source in Path(__file__).parent.iterdir():
        if source.suffix in ('.gd','.tscn','.gdshader') or source.name.endswith('.gd.uid'):
            shutil.copy2(source, source_target / source.name)
    (destination / 'project.godot').write_text('''config_version=5
[application]
config/name="玩个球 · 成年鲸鱼娘互动样板"
run/main_scene="res://sample/menu.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/window_width_override=1280
window/size/window_height_override=720
window/size/min_width=960
window/size/min_height=540
window/stretch/mode="canvas_items"
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
anti_aliasing/quality/msaa_3d=3
''', encoding='utf-8')
    # Disable tangent generation on untextured eyelash/cavity surfaces; no model data is altered.
    for name in ('whale_adult','animations'):
        (models / (name + '.glb.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[params]\nmeshes/ensure_tangents=false\n', encoding='utf-8')
    (destination / 'export_presets.cfg').write_text('''[preset.0]
name="Windows Whale Sample"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="notices/*"
exclude_filter="preparation.json,*.log,evidence/*"
[preset.0.options]
binary_format/architecture="x86_64"
binary_format/embed_pck=true
application/modify_resources=false
debug/export_console_wrapper=0
''', encoding='utf-8')
    manifest = {
        'model_source':'https://github.com/ningfangtianwai-pixel/ai-girls-3d/releases/tag/v1.0.0',
        'animation_source':'https://opengameart.org/content/universal-animation-library',
        'scope':'Local standalone sample; gameplay and formal entry unchanged',
        'animation_method':'Small additive motion relative to source Idle reference, not full pose retargeting',
        'original_archives':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [args.model_archive,args.animation_archive]},
        'sources':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in source_target.iterdir()},
        'models':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in models.glob('*.glb')},
    }
    (destination / 'preparation.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    print(destination)

if __name__ == '__main__':
    main()
