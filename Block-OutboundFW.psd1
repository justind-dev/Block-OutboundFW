@{
    RootModule = 'Block-OutboundFW.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'a3f8b2c1-4d5e-6f7a-8b9c-0d1e2f3a4b5c'
    Author = 'PowerShell Firewall Manager'
    CompanyName = 'JustinD-Dev'
    Copyright = 'JustinD-Dev (c) 2025. All rights reserved.'
    Description = 'Manages Windows Firewall rules to block or unblock outbound network access for executables in a directory'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Block-OutboundFW')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Firewall', 'Security', 'Network', 'Windows', 'Outbound')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = @'
Version 2.0.0
- Refactored and cleaned code
- Improved error handling with structured logging and timestamps
- Added parameter validation for RulePrefix
'@
        }
    }
}
