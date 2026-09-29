# pyxas 
PyXAS is a python library for fast 2D/3D XANES analysis with graphic user interface (GUI) provided.


## Installation

```
step 1:
git clone https://github.com/gmysage/pyxas.git

step 2:
pip install -e .

step 3:
run the command:
run-pyxas
```

## Building a standalone Windows executable

To get a `pyxas.exe` that runs without a Python installation, run on the target Windows machine:

```
packaging\build_windows.bat
```

(or double-click it). The script detects the NVIDIA GPU and driver and installs the matching
CUDA build of PyTorch; without an NVIDIA GPU it builds a CPU-only version. It uses its own isolated
Python environment (`.venv-build`), so it does not touch an existing Python/Anaconda installation.

- Result: `dist\pyxas\pyxas.exe` (keep the whole `dist\pyxas` folder together)
- Options: `-Cpu` forces a CPU-only build, `-Clean` rebuilds the environment from scratch,
  e.g. `packaging\build_windows.bat -Clean`
- Errors and crash reports are written to `%USERPROFILE%\.pyxas\pyxas.log`

## Updates
A machine learning model is included to correct non-even backgroud in images.

## License
[BSD]


## Acknowledgement
We kindly request that you cite the following article:

1. Mingyuan Ge, Wah-Keat Lee. "PyXAS – an open-source package for 2D X-ray near-edge spectroscopy analysis", Journal of Synchrotron Radiation, 27, 567 (2020)
2. Zeyuan Li, Thomas Flynn, Tongchao Liu, Sizhan Liu, Wah-Keat Lee, Ming Tang, Mingyuan Ge. "Highly sensitive 2D X-ray absorption spectroscopy via physics informed machine learning", npj Computational Materials volume 10, 128 (2024) 


