"""从已有本机资源准备隔离样板；不下载、不接受许可、不修改正式工程。"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def local_reference(directory, name):
    path = (directory / name).resolve()
    if not path.is_relative_to(directory.resolve()) or not path.is_file():
        raise ValueError(f"Missing or outside model directory: {name}")
    return path


def prepare():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-directory", type=Path, required=True,
                        help="已解压的 DeepSeek-chan 模型目录（保留作者说明）")
    parser.add_argument("--addon-directory", type=Path, required=True,
                        help="教程034中已经验证的 addons/gd_cubism 目录")
    parser.add_argument("--fixture-name", default="deepseek_menu")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9_]+", args.fixture_name):
        parser.error("fixture-name 只能使用小写字母、数字和下划线")
    repo = Path(__file__).resolve().parents[2]
    destination = repo / ".local/art_audio_r2" / args.fixture_name
    if destination.exists():
        parser.error(f"拒绝覆盖已有实验目录，请换一个 fixture-name：{destination}")
    model_directory = args.model_directory.resolve()
    addon_directory = args.addon_directory.resolve()
    entries = list(model_directory.glob("*.model3.json"))
    if len(entries) != 1:
        parser.error("模型目录必须包含唯一原始 *.model3.json；不要使用已有派生 runtime 目录")
    if not list(addon_directory.rglob("*.gdextension")) or not list(addon_directory.rglob("*.dll")):
        parser.error("addon-directory 不是已编译的 gd_cubism 插件目录")

    entry = entries[0]
    data = read_json(entry)
    references = data["FileReferences"]
    # 公开运行包没有登记现有动作/表情；只生成派生入口，不改作者文件。
    if not references.get("Expressions"):
        references["Expressions"] = [
            {"Name": path.name.removesuffix(".exp3.json"), "File": path.relative_to(model_directory).as_posix()}
            for path in sorted(model_directory.rglob("*.exp3.json"))]
    if not references.get("Motions"):
        references["Motions"] = {}
        for path in sorted(model_directory.rglob("*.motion3.json")):
            name = path.name.removesuffix(".motion3.json")
            group = "Idle" if "idle" in name.lower() else name
            references["Motions"].setdefault(group, []).append({"File": path.relative_to(model_directory).as_posix()})
    required = [references["Moc"], *references["Textures"]]
    required += [references[key] for key in ["Physics", "Pose", "DisplayInfo", "UserData"] if references.get(key)]
    required += [item["File"] for item in references["Expressions"]]
    required += [item["File"] for group in references["Motions"].values() for item in group]
    for name in required:
        local_reference(model_directory, name)
    expression_names = {item["Name"] for item in references["Expressions"]}
    for name in ["脸红", "黑脸"]:
        if name not in expression_names:
            parser.error(f"选中模型缺少预期表情：{name}；不要把别的鲸鱼娘当成此模型")
    motions = references["Motions"]
    for group in ["Idle", "默认手切举手", "举手切默认手"]:
        if group not in motions:
            parser.error(f"选中模型缺少预期动作组：{group}")
    returning = read_json(local_reference(model_directory, motions["举手切默认手"][0]["File"]))
    profile = {
        "reactions": {"cheek": "脸红", "pet": "脸红", "annoyed": "黑脸", "greet": "脸红"},
        "idle": {"group": "Idle", "index": 0},
        "gesture": {"group": "默认手切举手", "index": 0},
        "return_gesture": {"group": "举手切默认手", "index": 0, "duration": returning["Meta"]["Duration"]}}

    destination.mkdir(parents=True)
    model_target = destination / "models/DeepSeek-chan"
    shutil.copytree(model_directory, model_target)
    # 4096 图集缩为菜单人物时需要 mip 层；只写夹具的 Godot 导入配置，不改原始 PNG。
    for name in references["Textures"]:
        import_path = Path(str(model_target / name) + ".import")
        if import_path.exists():
            config = import_path.read_text(encoding="utf-8-sig")
            config = re.sub(r"mipmaps/generate=(true|false)", "mipmaps/generate=true", config)
        else:
            config = '[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[params]\nmipmaps/generate=true\n'
        import_path.write_text(config, encoding="utf-8")
    shutil.copytree(addon_directory, destination / "addons/gd_cubism")
    source_target = destination / "tools/live2d_menu_sample"
    source_target.mkdir(parents=True)
    for path in Path(__file__).parent.iterdir():
        if path.suffix in [".gd", ".tscn"] or path.name.endswith(".gd.uid"):
            shutil.copy2(path, source_target / path.name)
    write_json(model_target / "runtime.model3.json", data)
    write_json(destination / "model_profile.json", profile)
    write_json(destination / "preparation.json", {
        "scope": "Local prototype only; no game redistribution permission inferred",
        "original_entry": entry.name,
        "original_model_files": {path.relative_to(model_directory).as_posix(): sha256(path)
                                 for path in sorted(model_directory.rglob("*")) if path.is_file()},
        "addon_dlls": {path.relative_to(addon_directory).as_posix(): sha256(path)
                       for path in sorted(addon_directory.rglob("*.dll"))},
        "sources": {path.name: sha256(path) for path in source_target.iterdir()},
        "references": required})
    (destination / "project.godot").write_text('''config_version=5
[application]
config/name="玩个球 · DeepSeek-chan 互动样板"
run/main_scene="res://tools/live2d_menu_sample/entry.tscn"
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
''', encoding="utf-8")
    # 原始 Cubism JSON、moc3 和作者说明不是 Godot 原生资源，必须显式包含。
    (destination / "export_presets.cfg").write_text('''[preset.0]
name="Windows DeepSeek Sample"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="*.json,*.moc3,*.txt"
exclude_filter="preparation.json"
[preset.0.options]
binary_format/architecture="x86_64"
binary_format/embed_pck=true
application/modify_resources=false
debug/export_console_wrapper=0
''', encoding="utf-8")
    print(str(destination))


if __name__ == "__main__":
    prepare()
