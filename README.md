# brightnessctl for Void Linux (x86_64-musl / Intel Skylake)

A hardware-specific Void Linux XBPS package for [brightnessctl](https://github.com/Hummer12007/brightnessctl), targeting **x86_64-musl** and Intel Skylake CPUs. The reference machine is the HP Pavilion x360 T0Y58PA with an Intel Core i3-6100U.

This repository packages upstream brightnessctl; it does not fork or patch the application source.

## Target and compatibility

- Distribution: Void Linux
- XBPS target: `x86_64-musl` only
- CPU target: Intel Skylake (`-O2 -march=skylake -mtune=skylake -fno-plt`)
- Reference CPU: Intel Core i3-6100U (2 cores / 4 threads)
- Graphics: Intel HD Graphics 520 using the i915 driver
- C library: musl
- Build system: upstream GNU Makefile

This is not a generic x86_64 binary. The Skylake compiler target may emit instructions unsupported by older x86_64 processors. It is not intended for pre-Skylake CPUs, glibc systems, or other architectures.

GitHub Actions builds the package on a hosted runner. The runner is only the build host; XBPS selects the `x86_64-musl` target and the recipe supplies the Skylake CPU flags. Build parallelism therefore follows the runner, not the laptop's two physical CPU cores.

## Package source and build

The package recipe follows Void Linux's [brightnessctl template](https://github.com/void-linux/void-packages/tree/master/srcpkgs/brightnessctl).

- Upstream release: **0.5.1**
- Source archive: `https://github.com/Hummer12007/brightnessctl/archive/0.5.1.tar.gz`
- SHA-256: `a68869e23f56ac4f2e28f1783002810ddbf10f95e1af9b48b2912fb169f46994`
- Build style: `gnu-makefile`
- Compiler tuning: `-O2 -march=skylake -mtune=skylake -fno-plt`
- Udev rules: installed in `/usr/lib/udev/rules.d`

The project is a small C utility that reads and writes kernel-exposed brightness controls. The flags have deliberately modest goals:

- `-O2` enables the normal GCC release optimizations without the code-size and compile-time trade-offs of `-O3`.
- `-march=skylake -mtune=skylake` lets GCC use and schedule instructions for the i3-6100U's Skylake microarchitecture.
- `-fno-plt` avoids Procedure Linkage Table call stubs for external functions in this dynamically linked executable.

LTO and PGO are intentionally not enabled. Upstream builds the utility from a single C translation unit, so LTO has little cross-file optimization to perform. PGO would add training/build complexity to a short-lived program whose work is dominated by sysfs and kernel operations. These choices avoid claiming speedups that have not been measured on the laptop.

## Install a release

Successful builds from `main` publish a versioned GitHub Release. The package tag for this optimized build is `0.5.1_2`, and its asset is:

```
brightnessctl-0.5.1_2.x86_64-musl.xbps
```

Download the package from [GitHub Releases](https://github.com/rmicro/brightnessctl/releases), then install it on a compatible Void Linux system:

```sh
sudo xbps-install ./brightnessctl-0.5.1_1.x86_64-musl.xbps
```

These are standalone package releases, not a signed, indexed XBPS repository.

## Device permissions

The upstream udev rules grant write access to backlight devices through the `video` group and LED devices through the `input` group. Add your account to the group relevant to the device you intend to control, then log out and back in:

```sh
sudo usermod -aG video "$USER"
# Add input only when you need to control LED-class devices:
sudo usermod -aG input "$USER"
```

The package does not provide a kernel driver. The kernel must expose a control under `/sys/class/backlight` or `/sys/class/leds`. On Intel Skylake laptops, the available backlight device depends on the kernel and graphics-driver configuration; the package does not assume a particular sysfs device name.

Inspect available controls with:

```sh
ls /sys/class/backlight
brightnessctl --list
```

The i915 driver commonly exposes an Intel backlight device through `/sys/class/backlight`, often named `intel_backlight`. The exact name is selected by the running kernel/firmware, so discover it instead of hard-coding it. Once listed, you can target that device explicitly:

```sh
brightnessctl --class=backlight info
# Or, when the listed device is named intel_backlight:
brightnessctl --device=intel_backlight info
```

## Build locally

On a Void Linux host, clone both repositories and overlay this package recipe into Void's package tree:

```sh
git clone https://github.com/rmicro/brightnessctl.git
git clone https://github.com/void-linux/void-packages.git

rm -rf void-packages/srcpkgs/brightnessctl
cp -a brightnessctl/srcpkgs/brightnessctl void-packages/srcpkgs/

cd void-packages
./xbps-src -A x86_64-musl binary-bootstrap
./xbps-src -A x86_64-musl pkg brightnessctl
```

The resulting package is written under `hostdir/binpkgs/`. On a glibc x86_64 build host, keep `-A x86_64-musl` on both commands.

## Validation and maintenance

Run the repository checks before pushing:

```sh
bash -n srcpkgs/brightnessctl/template
sh -n scripts/publish-release.sh
sh scripts/test-template.sh
```

When updating brightnessctl:

1. Update `version` and the source SHA-256 in `srcpkgs/brightnessctl/template`.
2. Keep revision 1 for the initial packaging of a new upstream version; increment it when packaging changes alter the built package.
3. Re-check Void's package template for changed build options, dependencies, or musl workarounds.
4. Run the validation checks and confirm `./xbps-src -A x86_64-musl pkg brightnessctl` succeeds.
5. Benchmark on the reference Skylake CPU before describing any performance change.

## References

- [Upstream brightnessctl](https://github.com/Hummer12007/brightnessctl)
- [Void Linux brightnessctl package](https://github.com/void-linux/void-packages/tree/master/srcpkgs/brightnessctl)
- [rnicro/tofi](https://github.com/rmicro/tofi) and [rnicro/velotype](https://github.com/rmicro/velotype), used as examples for architecture-specific XBPS packaging and release workflows.
