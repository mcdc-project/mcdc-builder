# MC/DC builder

A collection of machine-specific scripts for creating Python environments and installing [MC/DC](https://github.com/mcdc-project/mcdc).

Prepare and update the MC/DC checkout at `MCDC_DIR`.
Review the script's requirements and **Configuration** section, then run it on the target machine with the site's module system available.
Set `MCDC_DEPENDENCIES` to select optional groups (`dev`, `docs`, `vvp`), or use `"."` for core dependencies only.
Editable installation is enabled by default; set `MCDC_EDITABLE="false"` for a regular installation.
Replace `MACHINE` below with the name used in the script filename:

```bash
bash build-mcdc-MACHINE.sh
```

Each builder removes and recreates its configured Python environment.
After installation, activate the environment in each new shell.

## Available builders

| Machine | Script | Builder GPU support |
| --- | --- | --- |
| [Dane](https://hpc.llnl.gov/hardware/compute-platforms/dane) | [build-mcdc-dane.sh](build-mcdc-dane.sh) | CPU only |
| [OSU COE](https://it.engineering.oregonstate.edu/hpc) | [build-mcdc-osu_coe.sh](build-mcdc-osu_coe.sh) | CPU only |
| OSU COE NVIDIA | [build-mcdc-osu_coe_nvidia.sh](build-mcdc-osu_coe_nvidia.sh) | NVIDIA via CUDA |
| [Tuolumne](https://hpc.llnl.gov/hardware/compute-platforms/tuolumne) | [build-mcdc-tuolumne.sh](build-mcdc-tuolumne.sh) | AMD via ROCm/HIP |

## GPU builds

For GPU builds, prepare an updated [Harmonize](https://github.com/CEMeNT-PSAAP/harmonize) checkout at `HARMONIZE_DIR`.
For Tuolumne, set `WITH_GPU="true"`; the OSU COE NVIDIA builder always installs GPU support.
The NVIDIA builder uses CUDA 11.8, Python 3.11, GCC 10.3, MPICH, and Numba 0.63.1.
Its default paths are `$HOME/mcdc`, `$HOME/harmonize`, and `$HOME/venv/osu_coe_nvidia/mcdc`; adjust `WORKSPACE` or the individual paths in **Configuration** as needed.
