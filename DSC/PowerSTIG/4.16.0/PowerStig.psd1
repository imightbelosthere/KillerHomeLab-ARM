# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PowerStig.psm1'

    # Version number of this module.
    ModuleVersion = '4.16.0'

    # ID used to uniquely identify this module
    GUID = 'a132f6a5-8f96-4942-be25-b213ee7e4af3'

    # Author of this module
    Author = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright = 'Copyright (c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'The PowerStig module provides a set of PowerShell classes to access DISA STIG settings extracted from the xccdf. The module provides a unified way to access the parsed STIG data by enabling the concepts of:
    1. Exceptions (overriding and auto-documenting)
    2. Ignoring a single or entire class of rules (auto-documenting)
    3. Organizational settings to address STIG rules that have allowable ranges.

    This module is intended to be used by additional automation as a lightweight portable database to audit and enforce the parsed STIG data.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    CLRVersion = '4.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules  = @(
        @{ModuleName = 'AuditPolicyDsc'; ModuleVersion = '1.4.0.0'},
        @{ModuleName = 'AuditSystemDsc'; ModuleVersion = '1.1.0'},
        @{ModuleName = 'AccessControlDsc'; ModuleVersion = '1.4.3'},
        @{ModuleName = 'ComputerManagementDsc'; ModuleVersion = '8.4.0'},
        @{ModuleName = 'FileContentDsc'; ModuleVersion = '1.3.0.151'},
        @{ModuleName = 'GPRegistryPolicyDsc'; ModuleVersion = '1.2.0'},
        @{ModuleName = 'PSDscResources'; ModuleVersion = '2.12.0.0'},
        @{ModuleName = 'SecurityPolicyDsc'; ModuleVersion = '2.10.0.0'},
        @{ModuleName = 'SqlServerDsc'; ModuleVersion = '15.1.1'},
        @{ModuleName = 'WindowsDefenderDsc'; ModuleVersion = '2.2.0'},
        @{ModuleName = 'xDnsServer'; ModuleVersion = '1.16.0.0'},
        @{ModuleName = 'xWebAdministration'; ModuleVersion = '3.2.0'},
        @{ModuleName = 'CertificateDsc'; ModuleVersion = '5.0.0'},
        @{ModuleName = 'nx'; ModuleVersion = '1.0'}
    )

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'Adobe',
        'DotNetFramework',
        'FireFox',
        'IisServer',
        'IisSite',
        'InternetExplorer',
        'Chrome',
        'McAfee',
        'Office',
        'OracleJRE',
        'SqlServer',
        'WindowsClient',
        'WindowsDefender',
        'WindowsDnsServer',
        'WindowsFirewall',
        'WindowsServer',
        'Vsphere',
        'RHEL',
        'Ubuntu',
        'Edge'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-DomainName',
        'Get-Stig',
        'New-StigCheckList',
        'Get-StigRuleList',
        'Get-StigVersionNumber',
        'Get-PowerStigFilelist',
        'Split-BenchmarkId',
        'Get-StigRule',
        'Get-StigRuleExceptionString',
        'Backup-StigSettings',
        'Restore-StigSettings'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = 'DSC','DesiredStateConfiguration','STIG','PowerStig', 'PSModule'

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Microsoft/PowerStig/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Microsoft/PowerStig'

            # Prerelease string value if the release should be a prerelease.
            Prerelease = ''

            # ReleaseNotes of this module
            ReleaseNotes = '## [4.16.0] - 2023-03-16
            * Update PowerSTIG to Parse/Apply Red Hat Enterprise Linux 7 STIG V3R10: [#1193](https://github.com/microsoft/PowerStig/issues/1193)
            * Update PowerSTIG to Parse/Apply CAN_Ubuntu_18-04_LTS_V2R10_STIG: [#1191](https://github.com/microsoft/PowerStig/issues/1191)
            * Update PowerSTIG to Parse/Apply Microsoft IIS 10.0 STIG V2R8: [#1196](https://github.com/microsoft/PowerStig/issues/1196)
            * Update PowerSTIG to Parse/Apply Google Chrome V2R8 [#1192](https://github.com/microsoft/PowerStig/issues/1192)
            * Update PowerSTIG to Parse/Apply Microsoft IIS 8.5 Site V2R7 & Server STIG V2R5 [#1195](https://github.com/microsoft/PowerStig/issues/1195)
            * Update PowerSTIG to Parse/Apply Microsoft Office 365 ProPlus V2R8 #1194: [#1194](https://github.com/microsoft/PowerStig/issues/1194)
            * Update PowerSTIG to Parse/Apply Microsoft Windows Server 2022 V1R1 STIG - Ver 1, Rel 1: [#1190](https://github.com/microsoft/PowerStig/issues/1190)
            * Update Readme to reflect all covered technologies [#1184](https://github.com/microsoft/PowerStig/issues/1184)
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
