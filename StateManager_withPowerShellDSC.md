# Overall Steps

1. Create 4 S3 bucket for storing MOF, Compliance Report, DSC execution log and State Manager Execution log.
2. Create EC2 Service role that include AmazonEC2RoleforSSM, AmazonS3ReadOnlyAccess , SecretsManagerReadWrite  and add Inline Policy

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SSMPermissionsForTagAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ssm:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```

2. Authoring PowerShellDSC and create a Managed Object Format (MOF) files.
3. Add Credential in Secret Manager
4. Add Parameter in SSM Parameter Store
5. Create a fileshare and website content
6. Create SSM State Manager Association
7. Create AutoScaling Group

## Authoring PowerShellDSC

1. Create a powershell script, called webserver.ps1.

```PowerShell
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
```

2. Create MOF by executing the script. MOF are generated in the subfolder of the configuration name. In this case, it is MyDscConfiguration.

```PowerShell
.\webserver.ps1
```

3. Rename the MOF file (not necessary step) and upload it to S3 bucket.

```PowerShell
cp .\MyDscConfiguration\localhost.mof .\MyDscConfiguration\webserver.mof
aws s3 cp .\MyDscConfiguration\webserver.mof s3://siri-powershelldsc/webserver.mof
```

## Add Credential 
This credential is for accessing a fileshare.

1. Go to Secret Manager
2. Add a Secret. Select Other type of secrets for secret type.
3. The Scecret value need to be in this format.

```
{ 'Username': 'siriratk', 'Password': 'Replace with your password' }
```

Username is siriratk which is the username parameter of PSCredential function.

```
$credential = New-Object PSCredential('siriratk', $ss)
```
4. The name of the Secret also is the username parameter of PSCredential function.

## Add Parameter in SSM Parameter Store

1. Create Parameter for

Name: DestinationPath
Value: C:\WebSite

Name: SourcePath
Value: \\fs-0063407d71a5c7e44.workspace.sirirat.local\share\Data\WebSite

# Add fileshare and add website content

Copy index.html and index.aspx to \\fs-0063407d71a5c7e44.workspace.sirirat.local\share\Data\WebSite

##Create SSM State Manager Association

1. Go to System Manger, State Manager and click Create association. Enter Name.
2. Select *AWS-ApplyDSCMofs* for Document.
3. Enter Paramter

Mofs to Apply: s3:siri-powershelldsc:webserver.mof
Service Path: Default
Mof Operation Mode: Apply
Report Bucket Name: siri-powershelldsc-report
Status Bucket Name: siri-powershelldsc-logs
Module Source Bucket Name: NONE
Allow PS Gallery Module Source: True
Compliance Type: WebServer:DSC

4. For Targets, select Specifying tags. Enter 

Key: Role 
Value: App2-WebServer

5. Select every 30 minutes for schedule.
6. For Advanced options, Compliance severity select Critical.
7. For Output options, check Enable writing output to S3.

S3 bucket name: siri-ssm-logs
S3 key prefix: statemanager/powershelldsc/webserver

##Create AutoScaling Group

###Create Launch Configuration

1. In EC2 Console, click Launch Configuration, create a new Launch Configuration.
2. Select Microsoft Windows Server 2019 Base, t2.micro (free tier Eligible)
3. Name Lauch Configuration. Select IAM role created earlier. (Need SSMAccess, S3Read)
4. Select SG that allow port 80.
5. Click Create
6. Create AutoScaling Group from this Launch Configuration.
7. Name AutoScaling Group, enter Group size start with 2, select VPC and Subnet.
8. Select Keep this group at its initial size
9. Create Auto Scaling Group Tag

Key: Role 
Value: App2-WebServer

