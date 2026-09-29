# Build with:  pyinstaller packaging/pyxas.spec --noconfirm   (run from the repo root)
import os
import sys
from PyInstaller.utils.hooks import collect_all, collect_data_files

root = os.path.abspath(os.path.join(SPECPATH, '..'))

datas = [
    (os.path.join(root, 'pyxas', 'icon.png'), 'pyxas'),
    (os.path.join(root, 'pyxas', 'pyml', 'trained_model', '*.pth'), os.path.join('pyxas', 'pyml', 'trained_model')),
]
binaries = []
hiddenimports = ['pyxas', 'pyxas.pyxas_gui', 'pyxas.pyml']

for pkg in ['bm3d', 'bm4d', 'xraylib', 'pystackreg', 'skimage']:
    d, b, h = collect_all(pkg)
    datas += d
    binaries += b
    hiddenimports += h

icon = os.path.join(root, 'icon.png')
if sys.platform == 'darwin':
    icon = None

a = Analysis(
    [os.path.join(SPECPATH, 'pyxas_launcher.py')],
    pathex=[root],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    excludes=['tkinter', 'PyQt6', 'PySide2', 'PySide6', 'IPython', 'jupyter', 'notebook'],
    noarchive=False,
)

# PyInstaller may pick up an outdated MSVC runtime from PATH (e.g. Anaconda's 14.2x), which crashes current torch.
if sys.platform == 'win32':
    msvc = {'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll', 'vcruntime140.dll',
            'vcruntime140_1.dll', 'concrt140.dll'}
    sys32 = os.path.join(os.environ.get('SystemRoot', r'C:\Windows'), 'System32')
    fixed = []
    for dest, src, kind in a.binaries:
        name = os.path.basename(dest).lower()
        if name in msvc and os.path.exists(os.path.join(sys32, name)):
            src = os.path.join(sys32, name)
        fixed.append((dest, src, kind))
    a.binaries = fixed

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='pyxas',
    console=False,
    icon=icon,
    upx=False,
)
coll = COLLECT(exe, a.binaries, a.datas, name='pyxas', upx=False)

if sys.platform == 'darwin':
    app = BUNDLE(coll, name='PyXAS.app', icon=None, bundle_identifier='org.pyxas.app')
