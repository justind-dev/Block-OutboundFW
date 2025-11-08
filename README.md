# Block-OutboundFW

A PowerShell module for recursively creating Windows Firewall rules to block outbound network access for all executables in a given directory.

[![License](https://img.shields.io/github/license/YOUR_USERNAME/Block-OutboundFW?style=flat-square)](https://github.com/YOUR_USERNAME/Block-OutboundFW/blob/main/LICENSE)
[![Issues](https://img.shields.io/github/issues/YOUR_USERNAME/Block-OutboundFW?style=flat-square)](https://github.com/YOUR_USERNAME/Block-OutboundFW/issues)
[![Forks](https://img.shields.io/github/forks/YOUR_USERNAME/Block-OutboundFW?style=flat-square)](https://github.com/YOUR_USERNAME/Block-OutboundFW/network/members)
[![Stars](https://img.shields.io/github/stars/YOUR_USERNAME/Block-OutboundFW?style=flat-square)](https://github.com/YOUR_USERNAME/Block-OutboundFW/stargazers)

## What It Does

Scans a directory recursively for executable files (`.exe`, `.com`, `.bat`, `.cmd`) and creates Windows Firewall rules to block their outbound network traffic across all firewall profiles (Domain, Private, Public). Rules are easily identifiable and can be removed with a single command.

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Administrator privileges
- Tested with PowerShell 5.1.26100.2161

## Installation

### Option 1: Manual Installation

1. Clone this repository
```powershell
git clone https://github.com/YOUR_USERNAME/Block-OutboundFW.git
```

2. Copy the module to your PowerShell modules directory
```powershell
Copy-Item -Path ".\Block-OutboundFW" -Destination "$HOME\Documents\PowerShell\Modules\" -Recurse
```

### Option 2: For Chris Titus Tech PowerShell Profile Users

If you're using the [Chris Titus Tech PowerShell Profile](https://github.com/ChrisTitusTech/powershell-profile), your `$env:PSModulePath` already includes custom module directories. Simply place the module folder in any of those paths and it will auto-load.

## Usage

```powershell
# Block all executables in a directory
Block-OutboundFW -Directory "C:\Path\To\Block"

# Remove firewall rules (unblock)
Block-OutboundFW -Directory "C:\Path\To\Block" -Unblock

# Use a custom rule prefix for organization
Block-OutboundFW -Directory "C:\Games\SomeGame" -RulePrefix "GameBlock"
```

## Examples

**Example 1:** Block outbound traffic for all executables in a program directory
```powershell
Block-OutboundFW -Directory "C:\Program Files\MyApp"
```
Creates firewall rules for every `.exe`, `.com`, `.bat`, and `.cmd` file found recursively in the directory, blocking all outbound network access.

**Example 2:** Remove previously created firewall rules
```powershell
Block-OutboundFW -Directory "C:\Program Files\MyApp" -Unblock
```
Removes all firewall rules that were created for executables in the specified directory.

**Example 3:** Block multiple directories via pipeline
```powershell
"C:\Games\Game1", "C:\Games\Game2" | Block-OutboundFW
```
Processes multiple directories in sequence, creating firewall rules for executables in each location.

## Available Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Directory` | String | Yes | - | Path to directory to scan for executables |
| `-Unblock` | Switch | No | False | Remove firewall rules instead of creating them |
| `-RulePrefix` | String | No | "BlockOutbound_Auto" | Prefix for firewall rule names (alphanumeric, underscore, hyphen only) |

## Getting Help

```powershell
Get-Help Block-OutboundFW -Full
```

## How It Works

1. Recursively scans the specified directory for executable files
2. Creates a uniquely named firewall rule for each executable using the pattern: `{RulePrefix} - {RelativePath}`
3. All rules block outbound traffic and are enabled across all firewall profiles
4. Rules can be easily identified in Windows Firewall by the prefix (default: "BlockOutbound_Auto")

## Notes

- **Requires Administrator privileges** - Firewall rule management requires elevated permissions
- **Supports `-WhatIf`** - Preview changes before applying them
- **Supports `-Confirm`** - Prompts for confirmation on each rule creation/removal
- **Pipeline support** - Process multiple directories in a single command
- **Idempotent** - Running the command multiple times won't create duplicate rules

## Disclaimer

This software is provided "as is" without warranty of any kind, express or implied. Use at your own risk. The author is not responsible for any damage, data loss, security issues, or other consequences resulting from the use of this software. Always test in a safe environment before deploying to production systems.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Easily manage outbound firewall rules for directories.*
