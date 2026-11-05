"""从已有夹具准备F5菜单的本机资源，不下载、安装、接受许可或打发行包。"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def copy_existing(source, destination):
    # 此工具只创建/补齐同一版本，不升级覆盖；Windows已加载的相同DLL也不必重写。
    if destination.exists():
        if destination.is_file() and digest(source) == digest(destination):return
        raise ValueError('保留已有文件，不覆盖: '+str(destination))
    created=False
    try:
        with source.open('rb') as incoming,destination.open('xb') as outgoing:
            created=True
            shutil.copyfileobj(incoming,outgoing)
        shutil.copystat(source,destination)
    except BaseException:
        if created:destination.unlink(missing_ok=True)
        raise


def write_json_atomic(path,value):
    name=None
    try:
        with tempfile.NamedTemporaryFile(mode='w',encoding='utf-8',dir=path.parent,prefix='.prepare-',suffix='.tmp',delete=False) as stream:
            name=Path(stream.name)
            json.dump(value,stream,ensure_ascii=False,indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name,path)
    finally:
        if name is not None:name.unlink(missing_ok=True)


def local_file(directory,relative):
    path=(directory/relative).resolve()
    if not path.is_relative_to(directory.resolve()) or not path.is_file():
        raise ValueError('来源文件缺失或路径越界: '+str(relative))
    return path


def main():
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,default=repo/'.local/art_audio_r2/deepseek_menu_visual_v2')
    args = parser.parse_args()
    source = args.source.resolve()
    model = (source/'models/DeepSeek-chan').resolve()
    native = (source/'addons/gd_cubism').resolve()
    if not model.is_relative_to(source) or not native.is_relative_to(source):raise ValueError('来源目录越界')
    entry = local_file(model,'runtime.model3.json')
    data = json.loads(entry.read_text(encoding='utf-8-sig'))
    refs = data['FileReferences']
    for relative in [refs['Moc'],*refs['Textures']]:
        local_file(model,relative)
    planned=[]
    for path in sorted(model.rglob('*')):
        if not path.is_file() or path.suffix not in {'.json','.moc3','.png','.txt','.md'}:continue
        relative=path.relative_to(model)
        planned.append((local_file(model,relative),Path('model')/relative))
    texture_cache={}
    for index,relative in enumerate(refs['Textures']):
        config=Path(str(model/relative)+'.import')
        if not config.is_file():continue
        if not config.resolve().is_relative_to(model):raise ValueError('图集配置路径越界')
        text=config.read_text(encoding='utf-8-sig')
        match=re.search(r'^path="res://(\.godot/imported/[^"]+\.ctex)"',text,re.M)
        if not match or 'mipmaps/generate=true' not in text:continue
        cached=(source/match[1]).resolve()
        if not cached.is_relative_to(source):raise ValueError('图集缓存路径越界')
        if not cached.is_file():continue
        destination=Path('textures')/f'{index}.ctex'
        planned.append((cached,destination));texture_cache[relative]=destination.as_posix()
    native_files=['gd_cubism.gdextension','bin/libgd_cubism.windows.debug.x86_64.dll','bin/libgd_cubism.windows.release.x86_64.dll']
    native_files += ['res/shader/2d_cubism_'+name+'.gdshader' for name in ['norm_add','norm_mix','norm_mul','mask','mask_add','mask_add_inv','mask_mix','mask_mix_inv','mask_mul','mask_mul_inv']]
    for relative in native_files:planned.append((local_file(native,relative),Path('native')/relative))
    target = (repo/'.local/menu_character_runtime').resolve()
    if not target.is_relative_to(repo.resolve()):raise ValueError('目标目录越界')
    manifest = target/'preparation.json'
    if target.exists() and not manifest.is_file():
        raise ValueError('拒绝覆盖未由本工具管理的目录: '+str(target))
    if manifest.is_file() and json.loads(manifest.read_text(encoding='utf-8')).get('owner') != 'prepare_menu_live2d_v1':
        raise ValueError('已有资源目录的归属不匹配')
    if manifest.is_file():
        previous=json.loads(manifest.read_text(encoding='utf-8'))
        for item in previous.get('files',[]):
            existing=(target/item['path']).resolve()
            if not existing.is_relative_to(target.resolve()):raise ValueError('已有清单路径越界')
            if existing.is_file() and digest(existing) != item['sha256']:
                raise ValueError('本机资源已修改，拒绝覆盖: '+item['path'])
    # 所有来源、已有文件冲突和profile先完整检查，再补齐文件；失败绝不提前清空旧清单。
    files=[]
    for incoming,relative in planned:
        dest=(target/relative).resolve()
        if not dest.is_relative_to(target):raise ValueError('目标文件路径越界')
        expected=digest(incoming)
        if dest.exists() and (not dest.is_file() or digest(dest) != expected):
            raise ValueError('本机资源与来源不同，保留不覆盖: '+str(relative))
        files.append({'path':relative.as_posix(),'sha256':expected})
    profile={'reactions':{'pet':'脸红','cheek':'脸红','greet':'脸红','annoyed':'黑脸'},'idle':{'group':'Idle','index':0},'texture_cache':texture_cache}
    existing_profile=target/'menu_profile.json'
    if existing_profile.is_file():
        if not existing_profile.resolve().is_relative_to(target):raise ValueError('配置路径越界')
        profile=json.loads(existing_profile.read_text(encoding='utf-8-sig'))
        if not isinstance(profile,dict):raise ValueError('本机profile不是对象')
        profile['texture_cache']=texture_cache
    target.mkdir(parents=True,exist_ok=True)
    for incoming,relative in planned:
        dest=target/relative;dest.parent.mkdir(parents=True,exist_ok=True);copy_existing(incoming,dest)
    ignore=target/'native/.gdignore'
    if not ignore.exists():ignore.write_text('',encoding='utf-8')
    write_json_atomic(target/'menu_profile.json',profile)
    write_json_atomic(manifest,{'owner':'prepare_menu_live2d_v1','source':str(source),'scope':'Local menu evaluation; no redistribution permission inferred','files':files})
    print(str(target))
    print('请用固定Godot4.7.1打开当前工程并F5；私有资源不进入普通导出暂存目录。')


if __name__ == '__main__':
    main()
