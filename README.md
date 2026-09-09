# MC/DC builder

A collection of machine-specific scripts for creating Python environments and
installing [MC/DC](https://github.com/mcdc-project/mcdc).

Prepare the MC/DC checkout manually, selecting the branch and updates you need.
Set paths and versions in the script's **Configuration** section, then run it on
the target machine with the required site modules available:

```bash
bash build-mcdc-<machine>.sh
```

Builders replace the configured Python environment. Review any additional
requirements in the script, and activate the environment after installation.

## Available builders

| Machine | Script | GPU support |
| --- | --- | --- |
| [Dane](https://hpc.llnl.gov/hardware/compute-platforms/dane) | [build-mcdc-dane.sh](build-mcdc-dane.sh) | None configured (CPU only) |
| [OSU COE](https://it.engineering.oregonstate.edu/hpc) | [build-mcdc-osu_coe.sh](build-mcdc-osu_coe.sh) | None configured (CPU only) |
| [Tuolumne](https://hpc.llnl.gov/hardware/compute-platforms/tuolumne) | [build-mcdc-tuolumne.sh](build-mcdc-tuolumne.sh) | AMD via ROCm/HIP |

For GPU builds, set `WITH_GPU="true"` and provide an existing Harmonize checkout
at `HARMONIZE_DIR`, manually updated on `main`. Builders install MC/DC and
Harmonize as provided; they do not switch branches or pull updates.
