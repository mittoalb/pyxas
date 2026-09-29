from setuptools import setup, find_packages

setup(
    name="pyxas",
    version="0.1.0",
    # find_packages() searches for folders with __init__.py
    packages=find_packages(),
    package_dir={"": "."}, 
    # List your dependencies here
    install_requires=[
        "pandas",
        "scikit-image",
        "scikit-learn",
        "numpy", 
        # 3.10 changed default image resampling, which alters how fitted maps are rendered
        "matplotlib<3.10",
        "pystackreg",
        "xraylib",
        "h5py",
        "bm3d",
        "scipy",
        "Pillow",
        "tqdm",
        "PyQt5",
        "torch",
        "torchvision",
    ],
    package_data={"pyxas": ["icon.png"], "pyxas.pyml": ["trained_model/*.pth"]},
    entry_points={
        'console_scripts': [
            'run-pyxas = pyxas.pyxas_gui:main',
        ],
    },
    # Metadata
    author="Mingyuan Ge",
    description="A Python package for 2D-XAS data analysis",
    python_requires=">=3.7",
)

