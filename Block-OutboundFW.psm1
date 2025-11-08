function Block-OutboundFW {
    <#
    .SYNOPSIS
        Manages Windows Firewall rules to block or unblock outbound network access for executables.

    .DESCRIPTION
        This module recursively scans a directory for executable files and creates Windows Firewall
        rules to block their outbound network access across all firewall profiles. Rules can be
        easily identified and removed using the -Unblock switch.

    .PARAMETER Directory
        The directory path to scan for executable files. Supports pipeline input.

    .PARAMETER Unblock
        Switch parameter to remove previously created firewall rules instead of creating them.

    .PARAMETER RulePrefix
        The prefix used to identify rules created by this module. Default is "BlockOutbound_Auto".

    .EXAMPLE
        Block-OutboundFW -Directory "C:\Program Files\MyApp"
        Creates firewall rules to block all executables in the specified directory.

    .EXAMPLE
        Block-OutboundFW -Directory "C:\Program Files\MyApp" -Unblock
        Removes all firewall rules created for the specified directory.

    .EXAMPLE
        "C:\App1", "C:\App2" | Block-OutboundFW
        Creates firewall rules for multiple directories via pipeline.

    .NOTES
        Author: JustinD-Dev
        Requires: Administrator privileges
        Version: 2.0
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (Test-Path -Path $_ -PathType Container) {
                $true
            } else {
                throw "The path '$_' does not exist or is not a directory."
            }
        })]
        [string]$Directory,

        [Parameter(Mandatory = $false)]
        [switch]$Unblock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9_\-]+$')]
        [string]$RulePrefix = "BlockOutbound_Auto"
    )

    begin {
        function Test-Administrator {
            $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
            return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        function New-FirewallRules {
            [CmdletBinding()]
            param(
                [string]$Path,
                [string]$Prefix
            )

            $ExecutableExtensions = @('*.exe', '*.com', '*.bat', '*.cmd')
            $Executables = @(Get-ChildItem -Path $Path -Recurse -File -Include $ExecutableExtensions -ErrorAction SilentlyContinue)

            if ($Executables.Count -eq 0) {
                Write-Warning "No executable files found in '$Path'"
                return
            }

            Write-Host "Found $($Executables.Count) executable(s)" -ForegroundColor Yellow

            foreach ($Executable in $Executables) {
                $script:ProcessedCount++

                try {
                    $RelativePath = $Executable.FullName.Replace($Path, '').TrimStart('\')
                    $RuleName = "$Prefix - $RelativePath"

                    $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

                    if ($ExistingRule) {
                        Write-Verbose "Rule already exists: $($Executable.Name)"
                        $script:SuccessCount++
                        continue
                    }

                    if ($PSCmdlet.ShouldProcess($Executable.FullName, "Create outbound block rule")) {
                        New-NetFirewallRule `
                            -DisplayName $RuleName `
                            -Description "Auto-generated outbound block rule: $($Executable.FullName)" `
                            -Direction Outbound `
                            -Action Block `
                            -Program $Executable.FullName `
                            -Profile Any `
                            -Enabled True `
                            -ErrorAction Stop | Out-Null

                        Write-Host "  [+] Blocked: $($Executable.Name)" -ForegroundColor Green
                        $script:SuccessCount++
                    }
                }
                catch {
                    Write-Warning "Failed to create rule for '$($Executable.Name)': $($_.Exception.Message)"
                    $script:FailureCount++
                    $script:ErrorLog += [PSCustomObject]@{
                        Path      = $Executable.FullName
                        Error     = $_.Exception.Message
                        Timestamp = Get-Date
                    }
                }
            }
        }

        function Remove-FirewallRules {
            [CmdletBinding()]
            param(
                [string]$Path,
                [string]$Prefix
            )

            $AllRules = @(Get-NetFirewallRule -DisplayName "$Prefix*" -ErrorAction SilentlyContinue)

            if ($AllRules.Count -eq 0) {
                Write-Warning "No firewall rules found with prefix '$Prefix'"
                return
            }

            $MatchingRules = @($AllRules | Where-Object {
                $ApplicationFilter = $_ | Get-NetFirewallApplicationFilter
                $ApplicationFilter.Program -like "$Path*"
            })

            if ($MatchingRules.Count -eq 0) {
                Write-Warning "No firewall rules found for directory '$Path'"
                return
            }

            Write-Host "Found $($MatchingRules.Count) rule(s) to remove" -ForegroundColor Yellow

            foreach ($Rule in $MatchingRules) {
                $script:ProcessedCount++

                try {
                    $ApplicationFilter = $Rule | Get-NetFirewallApplicationFilter

                    if ($PSCmdlet.ShouldProcess($ApplicationFilter.Program, "Remove outbound block rule")) {
                        Remove-NetFirewallRule -Name $Rule.Name -ErrorAction Stop
                        Write-Host "  [-] Removed: $($Rule.DisplayName)" -ForegroundColor Green
                        $script:SuccessCount++
                    }
                }
                catch {
                    Write-Warning "Failed to remove rule '$($Rule.DisplayName)': $($_.Exception.Message)"
                    $script:FailureCount++
                    $script:ErrorLog += [PSCustomObject]@{
                        Path      = $Rule.DisplayName
                        Error     = $_.Exception.Message
                        Timestamp = Get-Date
                    }
                }
            }
        }

        if (-not (Test-Administrator)) {
            throw "This script requires administrator privileges. Please run PowerShell as Administrator."
        }

        $script:ProcessedCount = 0
        $script:SuccessCount = 0
        $script:FailureCount = 0
        $script:ErrorLog = @()

        Write-Verbose "Starting firewall rule management with prefix: $RulePrefix"
    }

    process {
        try {
            $ResolvedPath = Resolve-Path -Path $Directory -ErrorAction Stop
            Write-Host "`nProcessing directory: $ResolvedPath" -ForegroundColor Cyan

            if ($Unblock) {
                Remove-FirewallRules -Path $ResolvedPath -Prefix $RulePrefix
            } else {
                New-FirewallRules -Path $ResolvedPath -Prefix $RulePrefix
            }
        }
        catch {
            Write-Error "Failed to process directory '$Directory': $($_.Exception.Message)"
            $script:ErrorLog += [PSCustomObject]@{
                Path      = $Directory
                Error     = $_.Exception.Message
                Timestamp = Get-Date
            }
        }
    }

    end {
        Write-Host "`n=== Summary ===" -ForegroundColor Cyan
        Write-Host "Total items processed: $script:ProcessedCount"
        Write-Host "Successful operations: $script:SuccessCount" -ForegroundColor Green

        if ($script:FailureCount -gt 0) {
            Write-Host "Failed operations: $script:FailureCount" -ForegroundColor Red

            if ($script:ErrorLog.Count -gt 0) {
                Write-Host "`nError Details:" -ForegroundColor Yellow
                $script:ErrorLog | ForEach-Object {
                    Write-Host "  [$($_.Timestamp.ToString('HH:mm:ss'))] $($_.Path)" -ForegroundColor Yellow
                    Write-Host "    Error: $($_.Error)" -ForegroundColor Red
                }
            }
        }

        Write-Verbose "Firewall rule management completed"
    }
}

Export-ModuleMember -Function Block-OutboundFW
