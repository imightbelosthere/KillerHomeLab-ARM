@{
    # Version number of this module. This is controlled by gitversion.
    moduleVersion = '2.1.0'

    # ID used to uniquely identify this module
    GUID = 'b42ff085-bd2b-4232-90ba-02b4c780e2d9'

    # Author of this module
    Author = 'DSC Community'

    # Company or vendor of this module
    CompanyName = 'DSC Community'

    # Copyright statement for this module
    Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Module with DSC Resources for Remote Desktop Session Host'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'

    # Functions to export from this module
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # DSC resources to export from this module
    DscResourcesToExport = @('xRDCertificateConfiguration','xRDGatewayConfiguration','xRDLicenseConfiguration','xRDRemoteApp','xRDServer','xRDSessionCollection','xRDSessionCollectionConfiguration','xRDsessionDeployment','xRDSessionDeployment')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/dsccommunity/xRemoteDesktopSessionHost/blob/master/LICENSE'

            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/dsccommunity/xRemoteDesktopSessionHost'

            # ReleaseNotes of this module
            ReleaseNotes = '## [2.1.0] - 2022-08-07

### Added

- xRemoteDesktopSessionHost
  - New examples for the resources

### Changed

- xRemoteDesktopSessionHost
  - Pipeline deploy task updated to use image `ubuntu-latest`.
  - Update pipeline files to the latest from Sampler''s DSC Community template.
- xRDCertificateConfiguration
  - import of RemoteDesktop module is now global; resolves [issue #79](https://github.com/dsccommunity/xRemoteDesktopSessionHost/issues/79)
- xRDSessionCollection
  - Workaround for bug in Windows Server 2019. Added a conditional match on returned
    Collections from `Get-RDSessionCollection` to workaround bug scenario where multiple
    collections are returned instead of a single collection.

### Fixed

- xRDCertificateConfiguration
  - Verbose messages now uses the correct localized strings.

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
