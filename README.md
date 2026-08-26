# OpenOCD VeeR/SweRV ICCM Compatibility Patch

Minimal compatibility changes for using current upstream OpenOCD with VeeR/SweRV cores whose ICCM accepts **32-bit Abstract Memory Access only**.

The goal of this repository is deliberately narrow: keep upstream OpenOCD behavior intact and add only the ICCM access adaptation required to remove misleading memory-access errors during normal GDB/Eclipse debugging.

## Base OpenOCD version

Validated against:

```text
Open On-Chip Debugger 0.12.0+dev-02633-g2741efc60 (2026-08-24-02:40)
```

The tested OpenOCD binary reported commit:

```text
g2741efc60
```

When rebasing this patch onto a newer OpenOCD revision, compare `src/target/riscv/riscv-013.c` first and rerun the regression tests in `docs/TESTING.md`.

## Why this patch exists

The generic OpenOCD RISC-V 0.13 backend maps the debugger-requested element size directly to the RISC-V Debug Module Abstract Memory `AAMSIZE` field.

For example:

```text
GDB read16
    -> args.size = 2
    -> OpenOCD AAMSIZE = 16-bit
    -> ICCM rejects the transaction
    -> abstractcs.cmderr
    -> OpenOCD prints a visible memory access error
```

On the tested VeeR/SweRV ICCM implementation, an aligned 32-bit Abstract Memory access succeeds while a 16-bit ICCM Abstract Memory access fails.

This can be especially visible with Eclipse/CDT because normal source-level debugging may generate sub-word ICCM reads/writes while decoding instructions, inserting software breakpoints, refreshing disassembly, or restoring breakpoint contents.

In many cases debugging still continues correctly after these messages, but the repeated `Error:` output strongly suggests a broken target or unstable debug connection. This patch changes the transaction itself instead of hiding the log message.

## What is changed

Only the RISC-V Debug 0.13 memory backend is modified:

```text
src/target/riscv/riscv-013.c
```

The compatibility rule is:

```text
Debugger logical ICCM access
        |
        v
VeeR/SweRV ICCM adapter
        |
        v
aligned 32-bit Abstract Memory transactions only
```

Reads are reconstructed from one or more aligned 32-bit words.

Partial writes use 32-bit read-modify-write so bytes outside the logical debugger request are preserved.

Naturally aligned 32-bit ICCM accesses continue through the original upstream path.

Non-ICCM memory continues through the original upstream behavior.

## Scope

This repository intentionally does **not** attempt to reproduce the historical `swerv-openocd` fork.

It does not add a new debugger architecture, new GDB protocol, or large VeeR-specific command layer. The purpose is to keep the maintenance surface small and compatible with modern upstream OpenOCD.

The current patch is intended for the following observed behavior:

- RISC-V Debug Module 0.13 memory access
- VeeR/SweRV ICCM requiring aligned 32-bit Abstract Memory transactions
- GDB/Eclipse sub-word ICCM reads and writes
- RV32IMAC software-breakpoint workflows

## Current limitations

### ICCM address range is currently hard-coded

The current source uses:

```c
#define EH2_ICCM_START  ((target_addr_t)0xEE000000ULL)
#define EH2_ICCM_END    ((target_addr_t)0xEEFFFFFFULL)
```

This is a temporary compatibility range, not a general VeeR memory-map discovery mechanism.

ICCM location and size are build-configurable and may differ between SoC configurations. Before using this patch on another design, adjust the range to match the actual hardware configuration.

A future implementation could move this information to target configuration instead of keeping it in `riscv-013.c`, but that is intentionally outside the current minimal patch scope.

### ICCM only

The patch is not applied globally to RAM/DCCM/SoC memory. Those regions may support 8/16/32-bit accesses normally and should continue using upstream OpenOCD behavior.

### Debug access, not CPU load/store behavior

This patch changes debugger-side Abstract Memory transactions only. It does not modify the CPU ISA, instruction execution, ICCM hardware, or normal application load/store behavior.

### Read-modify-write is a debug-time operation

Partial ICCM writes require a read-modify-write sequence. The target is expected to be halted during Abstract Memory access, so this is acceptable for debugger use. It should not be treated as an atomic run-time memory primitive.

### Instruction-cache/fetch synchronization is separate

Some VeeR/SweRV configurations require an explicit debug-memory synchronization action after modifying instruction memory before resume. That target-specific synchronization is separate from this ICCM width adaptation and may be handled in the OpenOCD target configuration.




The important regression is not merely that OpenOCD starts. Test ICCM 32-bit and sub-word accesses and a repeated software-breakpoint workflow as described in `docs/TESTING.md`.

## Expected result

Before the compatibility adaptation, debugger activity may produce output such as:

```text
Failed to read memory via abstract access.
Failed to write memory via abstract access.
... abstract=skipped (abstract access cmderr)
```

After the patch, the same logical debugger operations are translated into legal aligned 32-bit ICCM transactions and those ICCM-width errors should disappear.

## Design policy

The project follows a minimal-change policy:

1. Prefer current upstream OpenOCD behavior.
2. Keep VeeR/SweRV-specific behavior inside the RISC-V 0.13 backend when possible.
3. Do not suppress real errors merely to make logs clean.
4. Adapt only behavior that has been reproduced against hardware.
5. Avoid porting unrelated historical `swerv-openocd` customizations.

## License

`riscv-013.c` is derived from OpenOCD and retains its original SPDX declaration:

```text
SPDX-License-Identifier: GPL-2.0-or-later
```

Any distribution of the modified OpenOCD source must continue to comply with the applicable GNU GPL requirements and preserve upstream attribution and license notices.

OpenOCD is an upstream project; this compatibility patch is not an official OpenOCD or VeeR release.
