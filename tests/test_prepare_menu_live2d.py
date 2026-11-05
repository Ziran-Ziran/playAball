"""本机资源准备的文件保护回归；只用临时小文件，不加载模型/DLL。"""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('prepare_menu',Path(__file__).resolve().parents[1]/'tools/prepare_menu_live2d.py')
PREPARE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PREPARE)
SHADERS = ['2d_cubism_'+name+'.gdshader' for name in ['norm_add','norm_mix','norm_mul','mask','mask_add','mask_add_inv','mask_mix','mask_mix_inv','mask_mul','mask_mul_inv']]


class PreparationProtection(unittest.TestCase):
    def setUp(self):
        self.temporary=tempfile.TemporaryDirectory()
        self.root=Path(self.temporary.name)
        self.source=self.root/'source'
        self.model=self.source/'models/DeepSeek-chan'
        self.native=self.source/'addons/gd_cubism'
        self.model.mkdir(parents=True)
        (self.model/'runtime.model3.json').write_text(json.dumps({'FileReferences':{'Moc':'fish.moc3','Textures':['fish.png']}}),encoding='utf-8')
        (self.model/'fish.moc3').write_bytes(b'model-fixture')
        (self.model/'fish.png').write_bytes(b'texture-fixture')
        for name in ['gd_cubism.gdextension','bin/libgd_cubism.windows.debug.x86_64.dll','bin/libgd_cubism.windows.release.x86_64.dll']+['res/shader/'+name for name in SHADERS]:
            p=self.native/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b'fixture-only')
        self.target=self.root/'.local/menu_character_runtime'
        self.manifest=self.target/'preparation.json'

    def tearDown(self):
        self.temporary.cleanup()

    def prepare(self):
        with patch.object(PREPARE,'__file__',str(self.root/'tools/prepare_menu_live2d.py')),patch.object(sys,'argv',['prepare_menu_live2d.py','--source',str(self.source)]),contextlib.redirect_stdout(io.StringIO()):
            PREPARE.main()

    def test_idempotent_and_custom_profile_preserved(self):
        self.prepare()
        p=self.target/'menu_profile.json';d=json.loads(p.read_text(encoding='utf-8'));d['reactions']['greet']='custom';p.write_text(json.dumps(d),encoding='utf-8')
        self.prepare()
        self.assertEqual(json.loads(p.read_text(encoding='utf-8'))['reactions']['greet'],'custom')

    def test_unmanaged_directory_is_never_overwritten(self):
        self.target.mkdir(parents=True);p=self.target/'notes.txt';p.write_bytes(b'user work')
        with self.assertRaises(ValueError):self.prepare()
        self.assertEqual(p.read_bytes(),b'user work')

    def test_modified_managed_file_keeps_file_and_manifest(self):
        self.prepare();before=self.manifest.read_bytes();p=self.target/'model/fish.png';p.write_bytes(b'user edit')
        with self.assertRaises(ValueError):self.prepare()
        self.assertEqual(p.read_bytes(),b'user edit');self.assertEqual(self.manifest.read_bytes(),before)

    def test_unlisted_name_collision_is_never_overwritten(self):
        self.prepare();before=self.manifest.read_bytes();(self.model/'new.json').write_bytes(b'new source');p=self.target/'model/new.json';p.write_bytes(b'unlisted user work')
        with self.assertRaises(ValueError):self.prepare()
        self.assertEqual(p.read_bytes(),b'unlisted user work');self.assertEqual(self.manifest.read_bytes(),before)

    def test_missing_release_dll_keeps_old_manifest(self):
        self.prepare();before=self.manifest.read_bytes();(self.native/'bin/libgd_cubism.windows.release.x86_64.dll').unlink()
        with self.assertRaises((ValueError,FileNotFoundError)):self.prepare()
        self.assertEqual(self.manifest.read_bytes(),before)

    def test_missing_shader_keeps_old_manifest(self):
        self.prepare();before=self.manifest.read_bytes();(self.native/'res/shader'/SHADERS[0]).unlink()
        with self.assertRaises(ValueError):self.prepare()
        self.assertEqual(self.manifest.read_bytes(),before)

    def test_copy_failure_keeps_old_manifest(self):
        self.prepare();before=self.manifest.read_bytes();(self.model/'extra.json').write_bytes(b'extra')
        with patch.object(PREPARE,'copy_existing',side_effect=OSError('simulated disk failure')):
            with self.assertRaises(OSError):self.prepare()
        self.assertEqual(self.manifest.read_bytes(),before)

    def test_manifest_path_escape_is_rejected(self):
        self.prepare();d=json.loads(self.manifest.read_text(encoding='utf-8'));d['files'].append({'path':'../outside.txt','sha256':'x'});self.manifest.write_text(json.dumps(d),encoding='utf-8');before=self.manifest.read_bytes()
        with self.assertRaises(ValueError):self.prepare()
        self.assertEqual(self.manifest.read_bytes(),before)


if __name__ == '__main__':
    unittest.main()
