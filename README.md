# Portable WSL Toolkit

Seamlessly use the same WSL system from an external drive across different Windows hosts.

This project is built to make a portable `ext4.vhdx`-based WSL2 environment move between machines with minimal friction, while keeping startup, registration, backup, and recovery consistent.

## Upstream Reference

This project is optimized and evolved from the original WSL portable script ideas and implementations:

- https://zhuanlan.zhihu.com/p/525955480
- https://gitee.com/chjfth/dailytools/tree/master/cmd-batch/WSL-green

## Project Positioning

This repository is a practical upgrade of an existing portable WSL script workflow, not a from-scratch WSL framework.

The goal is to make day-to-day cross-host usage more reliable and easier to operate by improving script structure, defaults, and maintenance flows.

## What Is Improved Compared to the Original Script Form

1. Script layering and readability:
    - top-level scripts for frequent daily actions
    - maintenance scripts grouped under `tools/`
    - low-level implementation and generated artifacts grouped under `_internal/`
2. Operational safety:
    - explicit stop flow before unplugging
    - safe backup entrypoint
    - scripted restore and rename workflows
3. Configuration management:
    - local runtime config with template separation
    - helper scripts for changing user and backup policy
4. Open-source publishing hygiene:
    - privacy-safe defaults and ignored generated/private files
    - README onboarding and troubleshooting guidance

This repository is designed for practical daily use:
- one-click start
- one-click safe stop before unplugging
- one-click safe backup
- maintenance tools grouped separately

## What This Project Solves

When a WSL environment is moved across drive letters or machines, default WSL registration often breaks.
This toolkit keeps startup and recovery predictable by:

1. keeping runtime data in the project folder
2. re-registering distro metadata when needed
3. separating daily scripts from maintenance scripts

## Requirements

- Windows 10 21H2+ or Windows 11
- WSL enabled
- WSL2 installed
- `wsl.exe` available in PATH
- Optional but recommended: Windows Terminal (`wt.exe`)

## Quick Start

If this folder already has a valid `ext4.vhdx`:

1. Double-click `run.bat`
2. Work as usual
3. Before unplugging the drive, double-click `stop.bat`
4. Create regular backups with `backup-safe.bat`

If you do not have `ext4.vhdx` yet, follow [Initial Setup](#initial-setup-create-a-usable-ext4vhdx).

## Repository Layout

```text
ubuntu2404/
|-- ext4.vhdx
|-- run.bat
|-- stop.bat
|-- backup-safe.bat
|-- tools/
|   |-- doctor.bat
|   |-- restore-replace.bat
|   |-- rename.bat
|   |-- set-user.bat
|   `-- set-backup.bat
`-- _internal/
    |-- config.bat (local, not for git)
    |-- config.example.bat
    |-- wsl-template.reg
    |-- wsl-active.reg (generated)
    |-- wslname.tmp (generated)
    |-- scripts/
    |   |-- launch.bat
    |   |-- register.bat
    |   |-- backup.bat
    |   `-- restore.bat
    `-- legacy/
```

## Daily Operations

### 1. Start WSL

- Run `run.bat`

### 2. Stop Before Unplugging

- Run `stop.bat`

`stop.bat` flushes filesystem buffers (`sync`) before termination to reduce data-loss risk.

### 3. Safe Backup

- Run `backup-safe.bat`

This uses a terminate-then-export flow for stable backup output.

## Maintenance Operations

Use scripts in `tools/`:

- `tools/doctor.bat`: check environment, registration, and filesystem presence
- `tools/restore-replace.bat`: restore from latest backup and replace current registration
- `tools/rename.bat`: safely rename distro registration
- `tools/set-user.bat`: change default Linux user in internal config
- `tools/set-backup.bat`: change backup retention count and backup directory

## Initial Setup: Create a Usable ext4.vhdx

This toolkit expects `ext4.vhdx` in the project root.
The recommended way is: export an existing distro and import it into this folder.

### Step-by-Step (Recommended)

1. Verify your source distro name:

```powershell
wsl -l -v
```

Use placeholders below:
- `<SOURCE_DISTRO>`: existing configured distro to clone
- `<PORTABLE_DISTRO_NAME>`: new distro name for this toolkit
- `<PROJECT_ROOT>`: this repository folder path

2. Stop source distro before export:

```powershell
wsl --terminate <SOURCE_DISTRO>
wsl --shutdown
```

3. Export source distro:

```powershell
wsl --export <SOURCE_DISTRO> D:\path\to\portable-wsl.tar
```

4. Import into this project folder:

```powershell
wsl --import <PORTABLE_DISTRO_NAME> <PROJECT_ROOT> D:\path\to\portable-wsl.tar --version 2
```

5. Confirm `ext4.vhdx` appears in `<PROJECT_ROOT>`.

6. Optionally set default Linux user:

```powershell
wsl -d <PORTABLE_DISTRO_NAME> -u root -- sh -lc "printf '[user]\ndefault=<LINUX_USER>\n' > /etc/wsl.conf"
wsl --terminate <PORTABLE_DISTRO_NAME>
```

7. Start daily workflow with `run.bat`.

## Privacy-Safe Publishing (GitHub)

This project intentionally separates public templates from private runtime data.

### Keep Local Only

- `_internal/config.bat`
- `_internal/config.before-rename.bat`
- `_internal/wsl-active.reg`
- `ext4.vhdx`
- backup/restore outputs (`*.tar`, `backup/`, `restored/`)

### Publish-Friendly Files

- `_internal/config.example.bat`
- scripts and docs

### If Sensitive Files Were Already Tracked

```powershell
git rm --cached _internal/config.bat _internal/wsl-active.reg
```

Then commit the cleanup and push.

## Configuration Guidance

Do not directly edit identity-related settings unless you know the impact.

- Distro name changes: use `tools/rename.bat`
- Default Linux user changes: use `tools/set-user.bat`
- Backup policy changes: use `tools/set-backup.bat`

### What Changing Default User Means

Changing `WSL_USER` changes only the default login account.
It does not rename Linux users or migrate user data.

Possible side effects:

1. shell profile differs (`.bashrc`, `.zshrc`)
2. SSH keys and user-installed tools may be missing in the new account
3. file ownership may prevent write access for the new account

## Troubleshooting

### Startup Fails After Drive Letter Change or Move

1. Run `tools/doctor.bat`
2. Run `run.bat`

### Terminal Tabs Do Not Merge

If `wt.exe` is available, launcher prefers Windows Terminal tab mode.
If not, scripts fall back to the current console.

### Intermittent External Drive Disconnects

Scripts can reduce operator mistakes but cannot fully mask hardware disconnects.

Recommended mitigations:

1. always run `stop.bat` before unplugging
2. avoid unstable USB hubs/cables
3. disable aggressive USB power saving in Windows
4. keep frequent backups with `backup-safe.bat`

## Known Boundaries

1. This project cannot fully prevent hardware-level disconnect issues.
2. If an external drive disconnects during active I/O, WSL may still encounter I/O errors.
3. The scripts reduce operational mistakes and recovery time, but they are not a replacement for stable hardware and power settings.

## FAQ

### Can I change distro name by editing config directly?

Do not do that. Use `tools/rename.bat`.
Direct edits can create duplicate registrations.

### Can I publish this project with my current local config?

Do not publish `_internal/config.bat`.
Publish `_internal/config.example.bat` instead.
