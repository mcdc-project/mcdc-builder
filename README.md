# MC/DC builder

A collection of machine-specific scripts for creating Python environments and
installing [MC/DC](https://github.com/CEMeNT-PSAAP/MCDC).

Edit the chosen script's **Configuration** section to set paths, branches, and
versions. Provide an existing MC/DC checkout, then run the script on its target
machine with the required site modules available:

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

For builders with GPU support, set `WITH_GPU="true"` in the configuration.
