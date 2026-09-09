# MC/DC builder

A collection of machine-specific scripts for creating Python environments and installing [MC/DC](https://github.com/mcdc-project/mcdc).

Prepare and update the MC/DC checkout at `MCDC_DIR`.
Review the script's requirements and **Configuration** section, then run it on the target machine with the site's module system available.
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
| [Tuolumne](https://hpc.llnl.gov/hardware/compute-platforms/tuolumne) | [build-mcdc-tuolumne.sh](build-mcdc-tuolumne.sh) | AMD via ROCm/HIP |

## GPU builds

For GPU builds, set `WITH_GPU="true"` and prepare an updated [Harmonize](https://github.com/CEMeNT-PSAAP/harmonize) checkout at `HARMONIZE_DIR`.
GPU builds also replace the ROCm LLVM source directory at `ROCM_LLVM_PY_DIR`.
Builders install MC/DC and Harmonize as provided; they do not switch branches or pull updates.
