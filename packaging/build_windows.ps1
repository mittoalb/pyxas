# Builds dist\pyxas\pyxas.exe on this machine, choosing the torch build that matches the local GPU.
# Usage (from anywhere):  powershell -ExecutionPolicy Bypass -File packaging\build_windows.ps1 [-Cpu] [-Clean]
param(
    [switch]$Cpu,    # force a CPU-only build
    [switch]$Clean   # recreate the build environment from scratch
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$venv = Join-Path $root '.venv-build'
$py = Join-Path $venv 'Scripts\python.exe'
Set-Location $root

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# --- 1. Pick the torch build for this machine --------------------------------
Step 'Detecting GPU'
$torchIndex = 'https://download.pytorch.org/whl/cpu'
$variant = 'CPU only'
$smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($Cpu) {
    Write-Host 'CPU-only build requested.'
} elseif (-not $smi) {
    Write-Host 'No NVIDIA GPU/driver found (nvidia-smi missing): building CPU-only.' -ForegroundColor Yellow
} else {
    $info = (& nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader | Select-Object -First 1).Split(',') | ForEach-Object { $_.Trim() }
    $gpu, $driver, $cc = $info[0], [double]($info[1].Split('.')[0]), [double]$info[2]
    Write-Host "GPU: $gpu | driver $($info[1]) | compute capability $cc"
    # CUDA 12.8 is required for RTX 50xx (sm_120) and needs driver >= 570; it drops GPUs older than sm_75.
    if ($driver -ge 570 -and $cc -ge 7.5) { $cuda = 'cu128' }
    elseif ($driver -ge 560)              { $cuda = 'cu126' }
    elseif ($driver -ge 522)              { $cuda = 'cu118' }
    else { $cuda = $null }
    if ($cuda) {
        $torchIndex = "https://download.pytorch.org/whl/$cuda"
        $variant = "CUDA ($cuda)"
    } else {
        Write-Host "Driver $($info[1]) is too old for current CUDA builds (need >= 522): building CPU-only. Update the NVIDIA driver to enable the GPU." -ForegroundColor Yellow
    }
}
Write-Host "Torch variant: $variant"

# --- 2. Isolated Python (uv-managed, not Anaconda: its old MSVC runtime crashes torch) ---
Step 'Preparing build environment'
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing uv (Python package manager)...'
    powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}
if ($Clean -and (Test-Path $venv)) { Remove-Item $venv -Recurse -Force }
if (-not (Test-Path $py)) {
    uv venv $venv --python 3.12 --python-preference only-managed
    if ($LASTEXITCODE) { throw 'Failed to create the build environment' }
}

# --- 3. Dependencies ---------------------------------------------------------
Step "Installing torch ($variant) - this can take a while on first run"
uv pip install --python $py torch torchvision --index-url $torchIndex --reinstall-package torch --reinstall-package torchvision
if ($LASTEXITCODE) { throw 'torch installation failed' }

Step 'Installing pyxas and PyInstaller'
uv pip install --python $py pyinstaller $root
if ($LASTEXITCODE) { throw 'pyxas installation failed' }

# PyQt5-Qt5 ships a 2020 MSVC runtime (14.26) that crashes when loaded next to current torch.
$qtBin = & $py -c "import PyQt5, os; print(os.path.join(os.path.dirname(PyQt5.__file__), 'Qt5', 'bin'))"
foreach ($d in 'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll', 'concrt140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    $sys = Join-Path "$env:SystemRoot\System32" $d
    if ((Test-Path $sys) -and (Test-Path (Join-Path $qtBin $d))) { Copy-Item $sys (Join-Path $qtBin $d) -Force }
}

# --- 4. Sanity check before the long build ------------------------------------
Step 'Checking the environment'
& $py -c @"
import torch
from PyQt5.QtWidgets import QApplication
import pyxas.pyxas_gui
print('torch', torch.__version__)
if torch.cuda.is_available():
    x = torch.randn(1024, 1024, device='cuda'); (x @ x).sum().item()
    print('GPU OK:', torch.cuda.get_device_name(0))
else:
    print('Running on CPU')
"@
if ($LASTEXITCODE) { throw 'Environment check failed (see error above)' }

# --- 5. Build ------------------------------------------------------------------
Step 'Building executable (several minutes)'
& (Join-Path $venv 'Scripts\pyinstaller.exe') (Join-Path $PSScriptRoot 'pyxas.spec') --noconfirm --distpath (Join-Path $root 'dist') --workpath (Join-Path $root 'build')
if ($LASTEXITCODE) { throw 'PyInstaller build failed' }

$exe = Join-Path $root 'dist\pyxas\pyxas.exe'
Step 'Done'
Write-Host "Executable: $exe" -ForegroundColor Green
Write-Host 'Keep the whole dist\pyxas folder together (pyxas.exe needs the _internal folder next to it).'
Write-Host "Logs/crash reports: $env:USERPROFILE\.pyxas\pyxas.log"
