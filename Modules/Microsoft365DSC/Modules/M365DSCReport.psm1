<#
.Description
This function creates a new HTML document from the specified exported configuration

.Functionality
Internal, Hidden
#>
function New-M365DSCConfigurationToHTML
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter()]
        [Array]
        $ParsedContent,

        [Parameter()]
        [System.String]
        $OutputPath,

        [Parameter()]
        [System.String]
        $TemplateName,

        [Parameter()]
        [Switch]
        $SortProperties
    )

    if ([System.String]::IsNullOrEmpty($TemplateName))
    {
        $TemplateName = "Configuration Report"
    }

    Write-Output "Generating HTML report"
    $fullHTML = "<!DOCTYPE html>"
    $fullHTML += "<html>"
    $fullHTML += "<body>"
    $fullHTML += "<h1>" + $TemplateName + "</h1>"
    $fullHTML += "<div style='width:100%;text-align:center;'>"
    $fullHTML += "<h2>Template Details</h2>"

    $totalCount = $parsedContent.Count
    $currentCount = 0
    foreach ($resource in $parsedContent)
    {
        $percentage = [math]::Round(($currentCount / $totalCount) * 100, 2)
        Write-Progress -Activity 'Processing generated DSC Object' -Status ("{0:N2} completed - $($resource.ResourceName)" -f $percentage) -PercentComplete $percentage

        $partHTML = "<div width='100%' style='text-align:center;'><table width='80%' style='margin-left:auto; margin-right:auto;'>"
        $partHTML += "<tr><th rowspan='" + ($resource.Keys.Count) + "' width='20%'>"
        try
        {
            $partHTML += "<img src='" + (Get-IconPath -ResourceName $resource.ResourceName) + "' />"
        }
        catch
        {
            Write-Verbose -Message $_
        }
        $partHTML += "</th>"

        $partHTML += "<th colspan='2' style='background-color:silver;text-align:center;' width='80%'>"
        $partHTML += "<strong>" + $resource.ResourceName + "</strong>"
        $partHTML += "</th></tr>"

        if ($SortProperties)
        {
            $properties = $resource.Keys | Sort-Object
        }
        else
        {
            $properties = $resource.Keys
        }

        foreach ($property in $properties)
        {
            if ($property -ne "ResourceName" -and $property -ne "Credential")
            {
                $partHTML += "<tr><td width='40%' style='padding:5px;text-align:right;border:1px solid black;'><strong>" + $property + "</strong></td>"
                $value = "`$Null"
                if ($null -ne $resource.$property)
                {
                    if ($resource.$property.GetType().Name -eq 'Object[]')
                    {
                        if ($resource.$property -and ($resource.$property[0].GetType().Name -eq 'Hashtable' -or
                                $resource.$property[0].GetType().Name -eq 'OrderedDictionary'))
                        {
                            $value = ""
                            foreach ($entry in $resource.$property)
                            {
                                foreach ($key in $entry.Keys)
                                {
                                    $value += "<li>$key = $($entry.$key)</li>"
                                }
                                $value += "<hr />"
                            }
                        }
                        else
                        {
                            $temp = $resource.$property -join ','
                            [array]$components = $temp.Split(',')
                            if ($components.Length -gt 0 -and
                                -not [System.String]::IsNullOrEmpty($temp))
                            {
                                $Value = "<ul>"
                                foreach ($comp in $components)
                                {
                                    $value += "<li>$comp</li>"
                                }
                                $value += "</ul>"
                            }
                        }
                    }
                    else
                    {
                        if (-not [System.String]::IsNullOrEmpty($resource.$property))
                        {
                            $value = ($resource.$property).ToString()
                        }
                    }
                }
                $partHTML += "<td width='40%' style='padding:5px;border:1px solid black;'>" + $value + "</td></tr>"
            }
        }

        $partHTML += "</table></div><br />"
        $fullHTML += $partHTML
        $fullHTML += "</body>"
        $fullHTML += "</html>"

        $currentCount++
    }

    if (-not [System.String]::IsNullOrEmpty($OutputPath))
    {
        Write-Output "Saving HTML report"
        $fullHtml | Out-File $OutputPath
    }

    Write-Output "Completed generating HTML report"
}

<#
.Description
This function creates a new JSON file from the specified exported configuration

.Functionality
Internal, Hidden
#>
function New-M365DSCConfigurationToJSON
{
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Array]
        $ParsedContent,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath
    )

    $jsonContent = $ParsedContent | ConvertTo-Json
    $jsonContent | Out-File -FilePath $OutputPath
}


<#
.Description
This function gets the URL to the logo of the workload of the specified resource

.Functionality
Internal, Hidden
#>
function Get-IconPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceName
    )

    if ($ResourceName.StartsWith("AAD"))
    {
        return "http://microsoft365dsc.com/Images/AzureAD.jpg"
    }
    elseif ($ResourceName.StartsWith("EXO"))
    {
        return "http://microsoft365dsc.com/Images/Exchange.jpg"
    }
    elseif ($ResourceName.StartsWith("O365"))
    {
        return "http://microsoft365dsc.com/Images/Office365.jpg"
    }
    elseif ($ResourceName.StartsWith("OD"))
    {
        return "http://microsoft365dsc.com/Images/OneDrive.jpg"
    }
    elseif ($ResourceName.StartsWith("PP"))
    {
        return "http://microsoft365dsc.com/Images/PowerApps.jpg"
    }
    elseif ($ResourceName.StartsWith("SC"))
    {
        return "http://microsoft365dsc.com/Images/SecurityAndCompliance.png"
    }
    elseif ($ResourceName.StartsWith("SPO"))
    {
        return "http://microsoft365dsc.com/Images/SharePoint.jpg"
    }
    elseif ($ResourceName.StartsWith("Teams"))
    {
        return "http://microsoft365dsc.com/Images/Teams.jpg"
    }
    return $null
}

<#
.Description
This function creates a new Excel document from the specified exported configuration

.Functionality
Internal, Hidden
#>
function New-M365DSCConfigurationToExcel
{
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Array]
        $ParsedContent,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath
    )

    $excel = New-Object -ComObject excel.application
    $excel.visible = $True
    $workbook = $excel.Workbooks.Add()
    $report = $workbook.Worksheets.Item(1)
    $report.Name = 'Report'
    $report.Cells.Item(1, 1) = "Component Name"
    $report.Cells.Item(1, 1).Font.Size = 18
    $report.Cells.Item(1, 1).Font.Bold = $True
    $report.Cells.Item(1, 2) = "Property"
    $report.Cells.Item(1, 2).Font.Size = 18
    $report.Cells.Item(1, 2).Font.Bold = $True
    $report.Cells.Item(1, 3) = "Value"
    $report.Cells.Item(1, 3).Font.Size = 18
    $report.Cells.Item(1, 3).Font.Bold = $True
    $report.Range("A1:C1").Borders.Weight = -4138
    $row = 2

    $parsedContent = Initialize-M365DSCReporting -ConfigurationPath $ConfigurationPath

    foreach ($resource in $parsedContent)
    {
        $beginRow = $row
        foreach ($property in $resource.Keys)
        {
            if ($property -ne "ResourceName" -and $property -ne "Credential")
            {
                $report.Cells.Item($row, 1) = $resource.ResourceName
                $report.Cells.Item($row, 2) = $property
                try
                {
                    if ([System.String]::IsNullOrEmpty($resource.$property))
                    {
                        $report.Cells.Item($row, 3) = "`$Null"
                    }
                    else
                    {
                        if ($resource.$property.GetType().Name -eq 'Object[]')
                        {
                            $value = $resource.$property -join ','
                            $report.Cells.Item($row, 3) = $value
                        }
                        else
                        {
                            $value = ($resource.$property).ToString().Replace("$", "")
                            $value = $value.Replace("@", "")
                            $value = $value.Replace("(", "")
                            $value = $value.Replace(")", "")
                            $report.Cells.Item($row, 3) = $value
                        }
                    }

                    $report.Cells.Item($row, 3).HorizontalAlignment = -4131
                }
                catch
                {
                    Write-Verbose -Message $_
                    Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                        -EventID 1 -Source $($MyInvocation.MyCommand.Source)
                }

                if ($property -in @("Identity", "Name", "IsSingleInstance", "DisplayName"))
                {
                    $OriginPropertyName = $report.Cells.Item($beginRow, 2).Text
                    $OriginPropertyValue = $report.Cells.Item($beginRow, 3).Text
                    $CurrentPropertyName = $report.Cells.Item($row, 2).Text
                    $CurrentPropertyValue = $report.Cells.Item($row, 3).Text

                    $report.Cells.Item($beginRow, 2) = $CurrentPropertyName
                    $report.Cells.Item($beginRow, 3) = $CurrentPropertyValue
                    $report.Cells.Item($row, 2) = $OriginPropertyName
                    $report.Cells.Item($row, 3) = $OriginPropertyValue

                    $report.Cells($beginRow, 1).Font.ColorIndex = 10
                    $report.Cells($beginRow, 2).Font.ColorIndex = 10
                    $report.Cells($beginRow, 3).Font.ColorIndex = 10
                    $report.Cells($beginRow, 1).Font.Bold = $true
                    $report.Cells($beginRow, 2).Font.Bold = $true
                    $report.Cells($beginRow, 3).Font.Bold = $true
                }
                $row++
            }
        }
        $rangeValue = "A$beginRow" + ":" + "C$row"
        $report.Range($rangeValue).Borders[8].Weight = -4138
    }
    $usedRange = $report.UsedRange
    $usedRange.EntireColumn.AutoFit() | Out-Null
    $workbook.SaveAs($OutputPath)
    $excel.Quit()
}

<#
.Description
This function creates a report from the specified exported configuration,
either in HTML or Excel format

.Parameter Type
The type of report that should be created: Excel or HTML.

.Parameter ConfigurationPath
The path to the exported DSC configuration that the report should be created for.

.Parameter OutputPath
The output path of the report.

.Example
New-M365DSCReportFromConfiguration -Type 'HTML' -ConfigurationPath 'C:\DSC\ConfigName.ps1' -OutputPath 'C:\Dsc\M365Report.html'

.Example
New-M365DSCReportFromConfiguration -Type 'Excel' -ConfigurationPath 'C:\DSC\ConfigName.ps1' -OutputPath 'C:\Dsc\M365Report.xlsx'

.Example
New-M365DSCReportFromConfiguration -Type 'JSON' -ConfigurationPath 'C:\DSC\ConfigName.ps1' -OutputPath 'C:\Dsc\M365Report.json'

.Functionality
Public
#>
function New-M365DSCReportFromConfiguration
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Excel', 'HTML', 'JSON')]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ConfigurationPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath
    )

    # Validate that the latest version of the module is installed.
    Test-M365DSCModuleValidity

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Event", "Report")
    $data.Add("Type", $Type)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    [Array] $parsedContent = Initialize-M365DSCReporting -ConfigurationPath $ConfigurationPath

    switch ($Type)
    {
        "Excel"
        {
            New-M365DSCConfigurationToExcel -ParsedContent $parsedContent -OutputPath $OutputPath
        }
        "HTML"
        {
            $template = Get-Item $ConfigurationPath
            $templateName = $Template.Name.Split('.')[0]
            New-M365DSCConfigurationToHTML -ParsedContent $parsedContent -OutputPath $OutputPath -TemplateName $templateName
        }
        "JSON"
        {
            New-M365DSCConfigurationToJSON -ParsedContent $parsedContent -OutputPath $OutputPath
        }
    }
}

<#
.Description
This function compares two provided DSC configuration to determine the delta.

.Parameter Source
Local path of the source configuration.

.Parameter Destination
Local path of the destination configuraton.

.Parameter SourceObject
Array that contains the list of configuration components for the source.

.Parameter DestinationObject
Array that contains the list of configuration components for the destination. |

.Example
Compare-M365DSCConfigurations -Source 'C:\DSC\source.ps1' -Destination 'C:\DSC\destination.ps1'

.Functionality
Public
#>
function Compare-M365DSCConfigurations
{
    [CmdletBinding()]
    [OutputType([System.Array])]
    param (
        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [System.String]
        $Destination,

        [Parameter()]
        [System.Boolean]
        $CaptureTelemetry = $true,

        [Parameter()]
        [Array]
        $SourceObject,

        [Parameter()]
        [Array]
        $DestinationObject
    )

    if ($CaptureTelemetry)
    {
        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
        $data.Add("Event", "Compare")
        Add-M365DSCTelemetryEvent -Data $data
        #endregion
    }

    [Array] $Delta = @()

    if (-not $SourceObject)
    {
        [Array] $SourceObject = Initialize-M365DSCReporting -ConfigurationPath $Source
    }
    if (-not $DestinationObject)
    {
        [Array] $DestinationObject = Initialize-M365DSCReporting -ConfigurationPath $Destination
    }

    # Loop through all items in the source array
    $i = 1
    foreach ($sourceResource in $SourceObject)
    {
        try
        {
            [array]$key = Get-M365DSCResourceKey -Resource $sourceResource
            Write-Progress -Activity "Scanning Source $Source...[$i/$($SourceObject.Count)]" -PercentComplete ($i / ($SourceObject.Count) * 100)
            [array]$destinationResource = $DestinationObject | Where-Object -FilterScript { $_.ResourceName -eq $sourceResource.ResourceName -and $_.($key[0]) -eq $sourceResource.($key[0]) }

            $keyname = $key[0..1] -join '\'
            $SourceKeyValue = $sourceResource.($key[0])
            # Filter on the second key
            if ($key.Count -gt 1)
            {
                [array]$destinationResource = $destinationResource | Where-Object -FilterScript { $_.ResourceName -eq $sourceResource.ResourceName -and $_.($key[1]) -eq $sourceResource.($key[1]) }
                $SourceKeyValue = $sourceResource.($key[0]), $sourceResource.($key[1]) -join '\'
            }
            if ($null -eq $destinationResource)
            {
                $drift = @{
                    ResourceName = $sourceResource.ResourceName
                    Key          = $keyName
                    KeyValue     = $SourceKeyValue
                    Properties   = @(@{
                            ParameterName      = '_IsInConfiguration_'
                            ValueInSource      = 'Present'
                            ValueInDestination = 'Absent'
                        })
                }
                $Delta += , $drift
                $drift = $null
            }
            else
            {
                [System.Collections.Hashtable]$destinationResource = $destinationResource[0]
                # The resource instance exists in both the source and the destination. Compare each property;
                foreach ($propertyName in $sourceResource.Keys)
                {
                    if ($propertyName -notin @("ResourceName", "ResourceId", "Credential", "CertificatePath", "CertificatePassword", "TenantId", "ApplicationId", "CertificateThumbprint", "ApplicationSecret"))
                    {
                        # Needs to be a separate nested if statement otherwise the ReferenceObject an be null and it will error out;
                        if ($destinationResource.ContainsKey($propertyName) -eq $false -or (-not [System.String]::IsNullOrEmpty($propertyName) -and
                                $null -ne (Compare-Object -ReferenceObject ($sourceResource.$propertyName)`
                                        -DifferenceObject ($destinationResource.$propertyName))))
                        {
                            if ($null -eq $drift)
                            {
                                $drift = @{
                                    ResourceName = $sourceResource.ResourceName
                                    Key          = $keyname
                                    KeyValue     = $SourceKeyValue
                                    Properties   = @(@{
                                            ParameterName      = $propertyName
                                            ValueInSource      = $sourceResource.$propertyName
                                            ValueInDestination = $destinationResource.$propertyName
                                        })
                                }

                                if ($destinationResource.Contains("_metadata_$($propertyName)"))
                                {
                                    $Metadata = $destinationResource."_metadata_$($propertyName)"
                                    $Level = $Metadata.Split('|')[0].Replace("### ", "")
                                    $Information = $Metadata.Split('|')[1]
                                    $drift.Properties[0].Add("_Metadata_Level", $Level)
                                    $drift.Properties[0].Add("_Metadata_Info", $Information)
                                }
                            }
                            else
                            {
                                $newDrift = @{
                                    ParameterName      = $propertyName
                                    ValueInSource      = $sourceResource.$propertyName
                                    ValueInDestination = $destinationResource.$propertyName
                                }
                                if ($destinationResource.Contains("_metadata_$($propertyName)"))
                                {
                                    $Metadata = $destinationResource."_metadata_$($propertyName)"
                                    $Level = $Metadata.Split('|')[0].Replace("### ", "")
                                    $Information = $Metadata.Split('|')[1]
                                    $newDrift.Add("_Metadata_Level", $Level)
                                    $newDrift.Add("_Metadata_Info", $Information)
                                }
                                $drift.Properties += $newDrift
                            }
                        }
                    }
                }

                # Do the scan the other way around because there's a chance that the property, if null, wasn't part of the source
                # object. By scanning against the destination we will catch properties that are not null on the source but not null in destination;
                foreach ($propertyName in $destinationResource.Keys)
                {
                    if ($propertyName -notin @("ResourceName", "ResourceId", "Credential", "CertificatePath", "CertificatePassword", "TenantId", "ApplicationId", "CertificateThumbprint", "ApplicationSecret"))
                    {
                        if (-not [System.String]::IsNullOrEmpty($propertyName) -and
                            -not $sourceResource.Contains($propertyName))
                        {
                            if ($null -eq $drift)
                            {
                                $drift = @{
                                    ResourceName = $sourceResource.ResourceName
                                    Key          = $keyName
                                    KeyValue     = $SourceKeyValue
                                    Properties   = @(@{
                                            ParameterName      = $propertyName
                                            ValueInSource      = $null
                                            ValueInDestination = $destinationResource.$propertyName
                                        })
                                }
                            }
                            else
                            {
                                $drift.Properties += @{
                                    ParameterName      = $propertyName
                                    ValueInSource      = $null
                                    ValueInDestination = $destinationResource.$propertyName
                                }
                            }
                        }
                    }
                }

                if ($null -ne $drift)
                {
                    $Delta += , $drift
                    $drift = $null
                }
            }
        }
        catch
        {
            Write-Verbose -Message "Error: $_"
        }
        $i++
    }
    Write-Progress -Activity "Scanning Source..." -Completed

    # Loop through all items in the destination array
    $i = 1
    try
    {
        foreach ($destinationResource in $DestinationObject)
        {
            try
            {
                [System.Collections.HashTable]$currentDestinationResource = ([array]$destinationResource)[0]
                $key = Get-M365DSCResourceKey -Resource $currentDestinationResource
                Write-Progress -Activity "Scanning Destination $Destination...[$i/$($DestinationObject.Count)]" -PercentComplete ($i / ($DestinationObject.Count) * 100)
                $sourceResource = $SourceObject | Where-Object -FilterScript { $_.ResourceName -eq $currentDestinationResource.ResourceName -and $_.($key[0]) -eq $currentDestinationResource.($key[0]) }
                $currentDestinationKeyValue = $currentDestinationResource.($key[0])

                # Filter on the second key
                if ($key.Count -gt 1)
                {
                    [array]$sourceResource = $sourceResource | Where-Object -FilterScript { $_.ResourceName -eq $currentDestinationResource.ResourceName -and $_.($key[1]) -eq $currentDestinationResource.($key[1]) }
                    $currentDestinationKeyValue = $currentDestinationResource.($key[0]), $currentDestinationResource.($key[1]) -join '\'
                }
                if ($null -eq $sourceResource)
                {
                    $drift = @{
                        ResourceName = $currentDestinationResource.ResourceName
                        Key          = $keyName
                        KeyValue     = $currentDestinationKeyValue
                        Properties   = @(@{
                                ParameterName      = 'Ensure'
                                ValueInSource      = 'Absent'
                                ValueInDestination = 'Present'
                            })
                    }
                    $Delta += , $drift
                    $drift = $null
                }
            }
            catch
            {
                Write-Verbose -Message "Error: $_"
            }
            $i++
        }
    }
    catch
    {
        Write-Verbose -Message "Error: $_"
    }
    Write-Progress -Activity "Scanning Destination..." -Completed

    return $Delta
}

<#
.Description
This function gets the key parameter for the specified resource

.Functionality
Internal, Hidden
#>
function Get-M365DSCResourceKey
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Resource
    )

    if ($Resource.Contains("IsSingleInstance"))
    {
        return @("IsSingleInstance")
    }
    elseif ($Resource.Contains("DisplayName"))
    {
        if ($Resource.ResourceName -eq 'AADMSGroup' -and -not [System.String]::IsNullOrEmpty($Resource.Id))
        {
            return @("Id")
        }
        if ($Resource.ResourceName -eq 'TeamsChannel' -and -not [System.String]::IsNullOrEmpty($Resource.TeamName))
        {
            # Teams Channel displaynames are not tenant-unique (e.g. "General" is almost in every team), but should be unique per team
            return @('TeamName', 'DisplayName')
        }
        if ($Resource.ResourceName -eq 'TeamsTeam' -and -not [System.String]::IsNullOrEmpty($Resource.MailNickName))
        {
            # Teams names are not unique
            return @('MailNickName', 'DisplayName')
        }
        return @("DisplayName")
    }
    elseif ($Resource.Contains("Identity"))
    {
        return @("Identity")
    }
    elseif ($Resource.Contains("Name"))
    {
        return @("Name")
    }
    elseif ($Resource.Contains("Url"))
    {
        return @("Url")
    }
    elseif ($Resource.Contains("Organization"))
    {
        return @("Organization")
    }
    elseif ($Resource.Contains("CDNType"))
    {
        return @("CDNType")
    }
    elseif ($Resource.Contains("Action") -and $Resource.ResourceName -eq 'SCComplianceSearchAction')
    {
        return @("SearchName", "Action")
    }
    elseif ($Resource.Contains("Workload") -and $Resource.ResourceName -eq 'SCAuditConfigurationPolicy')
    {
        return @("Workload")
    }
    elseif ($Resource.Contains("Title") -and $Resource.ResourceName -eq 'SPOSiteDesign')
    {
        return @("Title")
    }
    elseif ($Resource.Contains("SiteDesignTitle"))
    {
        return @("SiteDesignTitle")
    }
    elseif ($Resource.Contains("Key") -and $Resource.ResourceName -eq 'SPOStorageEntity')
    {
        return @("Key")
    }
    elseif ($Resource.Contains("Usage"))
    {
        return @("Usage")
    }
    elseif ($Resource.Contains("OrgWideAccount"))
    {
        return @("OrgWideAccount")
    }
}

<#
.Description
This function creates a delta HTML report between two provided exported
DSC configurations

.Parameter Source
The source DSC configuration to compare from.

.Parameter Destination
The destination DSC configuration to compare with.

.Parameter OutputPath
The output path of the delta report.

.Parameter DriftOnly
Specifies that only difference should be in the report.

.Parameter IsBlueprintAssessment
Specifies that the report is a comparison with a Blueprint.

.Parameter HeaderFilePath
Specifies that file that contains a custom header for the report.

.Parameter Delta
An array with difference, already compiled from another source.

.Example
New-M365DSCDeltaReport -Source 'C:\DSC\Source.ps1' -Destination 'C:\DSC\Destination.ps1' -OutputPath 'C:\Dsc\DeltaReport.html'

.Example
New-M365DSCDeltaReport -Source 'C:\DSC\Source.ps1' -Destination 'C:\DSC\Destination.ps1' -OutputPath 'C:\Dsc\DeltaReport.html' -DriftOnly $true

.Functionality
Public
#>
function New-M365DSCDeltaReport
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Source,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Destination,

        [Parameter()]
        [System.String]
        $OutputPath,

        [Parameter()]
        [System.Boolean]
        $DriftOnly = $false,

        [Parameter()]
        [System.Boolean]
        $IsBlueprintAssessment = $false,

        [Parameter()]
        [System.String]
        $HeaderFilePath,

        [Parameter()]
        [Array]
        $Delta
    )

    # Validate that the latest version of the module is installed.
    Test-M365DSCModuleValidity

    if ((Test-Path -Path $Source) -eq $false)
    {
        Write-Error "Cannot find file specified in parameter Source: $Source. Please make sure the file exists!"
        return
    }

    if ((Test-Path -Path $Destination) -eq $false)
    {
        Write-Error "Cannot find file specified in parameter Destination: $Destination. Please make sure the file exists!"
        return
    }

    if ($OutputPath -and (Test-Path -Path $OutputPath) -eq $false)
    {
        Write-Warning "File specified in parameter OutputPath already exists and will be overwritten: $OutputPath"
        Write-Warning "Make sure you specify a file that not exists, if you don't want the file to be overwritten!"
    }

    if ($PSBoundParameters.ContainsKey("HeaderFilePath") -and -not [System.String]::IsNullOrEmpty($HeaderFilePath) -and `
        (Test-Path -Path $HeaderFilePath) -eq $false)
    {
        Write-Error "Cannot find file specified in parameter HeaderFilePath: $HeaderFilePath. Please make sure the file exists!"
        return
    }

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Event", "DeltaReport")
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    Write-Verbose -Message 'Obtaining Delta between the source and destination configurations'
    if (-not $Delta)
    {
        if ($IsBlueprintAssessment)
        {
            # Parse the blueprint file, pass to Compare-M365DSCConfigurations as object (including comments aka metadata)
            [Array] $ParsedBlueprintWithMetadata = Initialize-M365DSCReporting -ConfigurationPath $Destination -IncludeComments:$true
            $Delta = Compare-M365DSCConfigurations -Source $Source -DestinationObject $ParsedBlueprintWithMetadata -CaptureTelemetry $false
        }
        Else
        {
            $Delta = Compare-M365DSCConfigurations -Source $Source -Destination $Destination -CaptureTelemetry $false
        }
    }

    $reportSB = [System.Text.StringBuilder]::new()
    #region Custom Header
    if (-not [System.String]::IsNullOrEmpty($HeaderFilePath))
    {
        try
        {
            $headerContent = Get-Content $HeaderFilePath
            [void]$reportSB.AppendLine($headerContent)
        }
        catch
        {
            Write-Verbose -Message $_
            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source)
        }
    }
    #endregion

    $ReportTitle = "Microsoft365DSC - Delta Report"
    if ($IsBlueprintAssessment)
    {
        $ReportTitle = "Microsoft365DSC - Blueprint Assessment Report"
        [void]$reportSB.AppendLine("<h1>Blueprint Assessment Report</h1>")
    }
    else
    {
        [void]$reportSB.AppendLine("<h1>Delta Report</h1>")
        [void]$reportSB.AppendLine("<p><strong>Comparing </strong>$Source <strong>to</strong> $Destination</p>")
    }
    [void]$reportSB.AppendLine("<html><head><meta charset='utf-8'><title>$ReportTitle</title></head><body>")
    [void]$reportSB.AppendLine("<div style='width:100%;text-align:center;'>")
    [void]$reportSB.AppendLine("<img src='http://Microsoft365DSC.com/Images/Promo.png' alt='Microsoft365DSC Slogan' width='500' />")
    [void]$ReportSB.AppendLine("</div>")

    [array]$resourcesMissingInSource = $Delta | Where-Object -FilterScript { $_.Properties.ParameterName -eq '_IsInConfiguration_' -and `
            $_.Properties.ValueInSource -eq 'Absent' }
    [array]$resourcesMissingInDestination = $Delta | Where-Object -FilterScript { $_.Properties.ParameterName -eq '_IsInConfiguration_' -and `
            $_.Properties.ValueInDestination -eq 'Absent' }
    [array]$resourcesInDrift = $Delta | Where-Object -FilterScript { $_.Properties.ParameterName -ne '_IsInConfiguration_' }

    if ($resourcesMissingInSource.Count -eq 0 -and $resourcesMissingInDestination.Count -eq 0 -and `
            $resourcesInDrift.Count -eq 0)
    {
        [void]$reportSB.AppendLine("<p><strong>No discrepancies have been found!</strong></p>")
    }
    elseif (-not $DriftOnly)
    {
        [void]$reportSB.AppendLine("<h2>Table of Contents</h2>")
        [void]$reportSB.AppendLine("<ul>")
        if ($resourcesMissingInSource.Count -gt 0)
        {
            [void]$reportSB.AppendLine("<li><a href='#Source'>Resources Missing in the Source</a>")
            [void]$reportSB.AppendLine(" <strong>(</strong>$($resourcesMissingInSource.Count)<strong>)</strong></li>")
        }
        if ($resourcesMissingInDestination.Count -gt 0)
        {
            [void]$reportSB.AppendLine("<li><a href='#Destination'>Resources Missing in the Destination</a>")
            [void]$reportSB.AppendLine(" <strong>(</strong>$($resourcesMissingInDestination.Count)<strong>)</strong></li>")
        }
        if ($resourcesInDrift.Count -gt 0)
        {
            [void]$reportSB.AppendLine("<li><a href='#Drift'>Resources Configured Differently</a>")
            [void]$reportSB.AppendLine(" <strong>(</strong>$($resourcesInDrift.Count)<strong>)</strong></li>")
        }
        [void]$reportSB.AppendLine("</ul>")
    }

    if ($resourcesMissingInSource.Count -gt 0 -and -not $DriftOnly)
    {
        [void]$reportSB.AppendLine("<br /><hr /><br />")
        [void]$reportSB.AppendLine("<a id='Source'></a><h2>Resources that are Missing in the Source</h2>")
        foreach ($resource in $resourcesMissingInSource)
        {
            [void]$reportSB.AppendLine("<table width='100%' cellspacing='0' cellpadding='5'>")
            [void]$reportSB.AppendLine("<tr>")
            [void]$reportSB.Append("<th style='width:25%;text-align:center;vertical-align:middle;border-left:1px solid black;")
            [void]$reportSB.Append("border-top:1px solid black;border-bottom:1px solid black;'>")
            $iconPath = Get-IconPath -ResourceName $resource.ResourceName
            [void]$reportSB.AppendLine("<img src='$iconPath' />")
            [void]$reportSB.AppendLine("</th>");
            [void]$reportSB.AppendLine("<th style='border:1px solid black;text-align:center;'>")
            [void]$reportSB.AppendLine("<h3>$($resource.ResourceName) - $($resource.Key) = $($resource.KeyValue)</h3>")
            [void]$reportSB.AppendLine("</th>")
            [void]$reportSB.AppendLine("</tr>")
            [void]$reportSB.AppendLine("</table>")
        }
    }

    if ($resourcesMissingInDestination.Count -gt 0 -and -not $DriftOnly)
    {
        [void]$reportSB.AppendLine("<br /><hr /><br />")
        [void]$reportSB.AppendLine("<a id='Destination'></a><h2>Resources that are Missing in the Destination</h2>")
        foreach ($resource in $resourcesMissingInDestination)
        {
            [void]$reportSB.AppendLine("<table width='100%' cellspacing='0' cellpadding='5'>")
            [void]$reportSB.AppendLine("<tr>")
            [void]$reportSB.Append("<th style='width:25%;text-align:center;vertical-align:middle;border-left:1px solid black;")
            [void]$reportSB.Append("border-top:1px solid black;border-bottom:1px solid black;'>")
            $iconPath = Get-IconPath -ResourceName $resource.ResourceName
            [void]$reportSB.AppendLine("<img src='$iconPath' />")
            [void]$reportSB.AppendLine("</th>");
            [void]$reportSB.AppendLine("<th style='border:1px solid black;text-align:center;'>")
            [void]$reportSB.AppendLine("<h3>$($resource.ResourceName) - $($resource.Key) = $($resource.KeyValue)</h3>")
            [void]$reportSB.AppendLine("</th>")
            [void]$reportSB.AppendLine("</tr>")
            [void]$reportSB.AppendLine("</table>")
        }
    }

    if ($resourcesInDrift.Count -gt 0)
    {
        [void]$reportSB.AppendLine("<br /><hr /><br />")
        [void]$reportSB.AppendLine("<a id='Drift'></a><h2>Resources that are Configured Differently</h2>")
        foreach ($resource in $resourcesInDrift)
        {
            [void]$reportSB.AppendLine("<table width='100%' cellspacing='0' cellpadding='5'>")
            [void]$reportSB.AppendLine("<tr>")
            [void]$reportSB.Append("<th style='width:25%;text-align:center;vertical-align:middle;border:1px solid black;;' ")
            [void]$reportSB.Append("rowspan='" + ($resource.Properties.Count + 2) + "'>")
            $iconPath = Get-IconPath -ResourceName $resource.ResourceName
            [void]$reportSB.AppendLine("<img src='$iconPath' />")
            [void]$reportSB.AppendLine("</th>");
            [void]$reportSB.AppendLine("<th style='border:1px solid black;text-align:center;vertical-align:middle;background-color:#CCC' colspan='3'>")
            [void]$reportSB.AppendLine("<h3>$($resource.ResourceName) - $($resource.Key) = $($resource.KeyValue)</h3>")
            [void]$reportSB.AppendLine("</th></tr>")
            [void]$reportSB.AppendLine("<tr>")

            $SourceLabel = "Source Value"
            $DestinationLabel = "Destination Value"
            if ($IsBlueprintAssessment)
            {
                $SourceLabel = "Tenant's Current Value"
                $DestinationLabel = "Blueprint's Value"
            }
            [void]$reportSB.AppendLine("<td style='text-align:center;border:1px solid black;background-color:#EEE;' width='45%'><strong>Property</strong></td>")
            [void]$reportSB.AppendLine("<td style='text-align:center;border:1px solid black;background-color:#EEE;' width='15%'><strong>$SourceLabel</strong></td>")
            [void]$reportSB.AppendLine("<td style='text-align:center;border:1px solid black;background-color:#EEE;' width='15%'><strong>$DestinationLabel</strong></td>")
            [void]$reportSB.AppendLine("</tr>")
            foreach ($drift in $resource.Properties)
            {
                if ($drift.ParameterName -notlike '_metadata_*')
                {
                    $cellStyle = ''
                    $emoticon = ''
                    if ($drift._Metadata_Level -eq 'L1')
                    {
                        $cellStyle = "background-color:#F6CECE;"
                        $emoticon = '&#x1F7E5;'
                    }
                    elseif ($drift._Metadata_Level -eq 'L2')
                    {
                        $cellStyle = "background-color:#F7F8E0;"
                        $emoticon = '&#x1F7E8;'
                    }
                    elseif ($drift._Metadata_Level -eq 'L3')
                    {
                        $cellStyle = "background-color:#FFFFFF;"
                        $emoticon = '&#x1F7E6;'
                    }

                    [void]$reportSB.AppendLine("<tr>")
                    [void]$reportSB.AppendLine("<td style='border:1px solid black;text-align:right;' width='45%'>")
                    [void]$reportSB.AppendLine("$($drift.ParameterName)</td>")
                    [void]$reportSB.AppendLine("<td style='border:1px solid black;$cellStyle' width='15%'>")
                    [void]$reportSB.AppendLine("$($drift.ValueInSource)</td>")
                    [void]$reportSB.AppendLine("<td style='border:1px solid black;' width='15%'>")
                    [void]$reportSB.AppendLine("$($drift.ValueInDestination)</td>")
                    [void]$reportSB.AppendLine("</tr>")

                    if ($null -ne $drift._Metadata_Level)
                    {
                        [void]$reportSB.AppendLine("<tr><td colspan='3' style='border:1px solid black;'>$emoticon $($drift._Metadata_Info)</td></tr>")
                    }
                }
            }
            [void]$reportSB.AppendLine("</table><hr/>")
        }
    }
    [void]$reportSB.AppendLine("</body></html>")
    if (-not [System.String]::IsNullOrEmpty($OutputPath))
    {
        $reportSB.ToString() | Out-File $OutputPath
        Invoke-Item $OutputPath
    }
    else
    {
        return $reportSB.ToString()
    }
}

<#
.Description
This function prepares the configuration for further parsing of the data

.Functionality
Internal, Hidden
#>
function Initialize-M365DSCReporting
{
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ConfigurationPath,

        [Parameter()]
        [Switch]
        $IncludeComments
    )

    if ((Test-Path -Path $ConfigurationPath) -eq $false)
    {
        Write-Error "Cannot find file specified in parameter Source: $ConfigurationPath. Please make sure the file exists!"
        return
    }

    Write-Output "Loading file '$ConfigurationPath'"

    $fileContent = Get-Content $ConfigurationPath -Raw
    try
    {
        $startPosition = $fileContent.IndexOf(" -ModuleVersion")
        if ($startPosition -gt 0)
        {
            $endPosition = $fileContent.IndexOf("`r", $startPosition)
            $fileContent = $fileContent.Remove($startPosition, $endPosition - $startPosition)
        }
    }
    catch
    {
        Write-Verbose "Error trying to remove Module Version"
    }

    if ($IncludeComments)
    {
        $parsedContent = ConvertTo-DSCObject -Content $fileContent -IncludeComments:$True
    }
    else
    {
        $parsedContent = ConvertTo-DSCObject -Content $fileContent
    }

    return $parsedContent

}

Export-ModuleMember -Function @(
    'Compare-M365DSCConfigurations',
    'New-M365DSCDeltaReport',
    'New-M365DSCReportFromConfiguration'
)
