Configuration MyDscConfiguration {
    Import-DscResource -Module xWebAdministration
    $ss = ConvertTo-SecureString -String 'a_string' -AsPlaintext -Force
    $credential = New-Object PSCredential('siriratk', $ss)
    Node "localhost" {
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
            DependsOn       = "[WindowsFeature]IIS"
        }

        File WebContent
        {
            Ensure          = "Present"
            SourcePath      = "{tagssm:SourcePath}"
            DestinationPath = "{tagssm:DestinationPath}"
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[WindowsFeature]AspNet45"
            Credential      = $credential
            MatchSource     = $true
        }

        xWebsite DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Started"
            PhysicalPath    = "{tagssm:DestinationPath}"
            DependsOn       = "[File]WebContent"
        }
    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}
MyDscConfiguration -ConfigurationData $cd 