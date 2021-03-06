# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
VerboseTestTargetSetting = CAP configuration item "{0}" does not match the desired state. 
VerboseTestTargetUsergroupAddAuthorization = Usergroup "{0}" not authorized.
VerboseTestTargetUsergroupRemoveAuthorization = Usergroup "{0}" autorization not specified in Configuration.
VerboseTestTargetTrueResult = The target resource is already in the desired state. No action is required. 
VerboseTestTargetFalseResult = The target resource is not in the desired state. 
VerboseSetTargetCapRuleCreated = Successfully created Connection Access Policy "{0}". 
VerboseSetTargetCapRuleRemoved = Successfully removed Connection Access Policy "{0}". 
VerboseSetTargetSetting = CAP configuration item "{0}" has been updated to "{1}".
VerboseSetTargetUsergroupRemoveAuthorization = Usergroup "{0}" removed from Usergroup container.
VerboseSetTargetUsergroupAddAuthorization = Usergroup "{0}" added to Usergroup container.
ErrorConnectionAccessPolicyFailure = Failure to get the requested connection access policy "{0}" information from the target machine.
'@

}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $RuleName
    )

    Assert-Module

    $itemPath = ("RDS:\GatewayServer\CAP\{0}" -f $RuleName)
    $capItem = Get-Item -Path $itemPath

    if($capItem -eq $null)
    {
        $EnsureResult = "Absent" 
    }
    elseif ($capItem.count -eq 1)
    {
        $EnsureResult = "Present" 
        $capSettings = Get-ChildItem $itemPath
        $userGroupPath = ('{0}\{1}' -f $itemPath, "UserGroups")
        $currentGroups = Get-ChildItem -Path $userGroupPath
    }
    else
    {
        $ErrorMessage = $LocalizedData.ErrorConnectionAccessPolicyFailure -f $RuleName 
        New-TerminatingError -ErrorId 'ConnectionAccessPolicyFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidResult' 
    }
    
    $returnValue = @{
    Ensure = [System.String]$EnsureResult
    RuleName = [System.String]$capItem.Name
    Usergroups = [System.String[]]$currentGroups
    Status = [System.String]($capSettings | ?{$_.Name -eq 'Status'}).CurrentValue
    AuthMethod = [System.String]($capSettings | ?{$_.Name -eq 'AuthMethod'}).CurrentValue
    AllowOnlySDRTSServers = [System.String]($capSettings | ?{$_.Name -eq 'AllowOnlySDRTSServers'}).CurrentValue
    IdleTimeout = [System.UInt32]($capSettings | ?{$_.Name -eq 'IdleTimeout'}).CurrentValue
    SessionTimeout = [System.UInt32]($capSettings | ?{$_.Name -eq 'SessionTimeout'}).CurrentValue
    SessionTimeoutAction = [System.String]($capSettings | ?{$_.Name -eq 'SessionTimeoutAction'}).CurrentValue
    EvaluationOrder = [System.UInt32]($capSettings | ?{$_.Name -eq 'EvaluationOrder'}).CurrentValue
    }

    $returnValue
    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $RuleName,

        [System.String[]]
        $Usergroups,

        [ValidateSet("0","1")]
        [System.String]
        $Status,

        [ValidateSet("0","1","2","3")]
        [System.String]
        $AuthMethod,

        [ValidateSet("0","1")]
        [System.String]
        $AllowOnlySDRTSServers,

        [System.UInt32]
        $IdleTimeout,

        [System.UInt32]
        $SessionTimeout,

        [System.String]
        $SessionTimeoutAction,

        [System.UInt32]
        $EvaluationOrder
    )

    Assert-Module

    $capItem = Get-ChildItem -Path RDS:\GatewayServer\CAP\ | ?{$_.Name -eq $RuleName}

    if($capItem -ne $null -and $Ensure -eq "Absent")
    {
        $capItem | Remove-Item -Confirm:$false
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetCapRuleRemoved -f $RuleName)
    }
    if($capItem -eq $null -and $Ensure -eq "Present")
    {
        $capItem = New-Item -Path RDS:\GatewayServer\CAP -Name $RuleName -AuthMethod $AuthMethod -UserGroups $Usergroups
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetCapRuleCreated -f $RuleName)
    }
    
    if($capItem -and $Ensure -eq "Present")
    {

        $capSettings = Get-childItem $capItem.PSPath
        $itemPath = $capSettings[0].ParentPath

        foreach ($setting in ($capSettings | Where Type -eq Integer))
        {
            if($PSBoundParameters.ContainsKey($setting.Name))
            {
                $param = (Get-Variable -Name $setting.Name)
                if($setting.CurrentValue -ne $param.Value)
                {
                    Set-Item -Path ('{0}\{1}' -f $itemPath, $setting.Name) -Value $param.Value
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetSetting -f $setting.Name, $param.Value)
                }
            }
        }
        
       if($PSBoundParameters.ContainsKey('Usergroups'))
        {
            $userGroupPath = ('{0}\{1}' -f $itemPath, "UserGroups")
            $currentGroups = Get-ChildItem -Path $userGroupPath
            $compareGroups = Compare-Object -ReferenceObject $userGroups -DifferenceObject $currentGroups
            if($compareGroups -ne $null)
            {
                $compareGroups | where SideIndicator -eq '<=' | ForEach {
                    New-Item -Path $userGroupPath -Name $_.InputObject
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetUsergroupAddAuthorization -f $_.InputObject)
                }
                $compareGroups | where SideIndicator -eq '=>' | ForEach {
                    Remove-Item -Path ($userGroupPath + '\' + $_.InputObject)
                    Write-Verbose -Message ($LocalizedData.VerboseSetTargetUsergroupRemoveAuthorization -f $_.InputObject)
                }
            }
        } 
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $RuleName,

        [System.String[]]
        $Usergroups,

        [ValidateSet("0","1")]
        [System.String]
        $Status,

        [ValidateSet("0","1","2","3")]
        [System.String]
        $AuthMethod,

        [ValidateSet("0","1")]
        [System.String]
        $AllowOnlySDRTSServers,

        [System.UInt32]
        $IdleTimeout,

        [System.UInt32]
        $SessionTimeout,

        [System.String]
        $SessionTimeoutAction,

        [System.UInt32]
        $EvaluationOrder
    )

Assert-Module

    $InDesiredState = $true

    $capItem = Get-ChildItem -Path RDS:\GatewayServer\CAP\ | ?{$_.Name -eq $RuleName}

    if(($capItem -eq $null -and $Ensure -eq "Present") -or ($capItem -ne $null -and $Ensure -eq "Absent"))
    {
        $InDesiredState = $false
    }

    if($capItem -ne $null -and $Ensure -eq "Present")
    {
        $capSettings = Get-childItem $capItem.PSPath
        $itemPath = $capSettings[0].ParentPath

        foreach ($setting in ($capSettings | Where Type -eq Integer))
        {
            if($PSBoundParameters.ContainsKey($setting.Name))
            {
                $param = (Get-Variable -Name $setting.Name)
                if($setting.CurrentValue -ne $param.Value)
                {
                    $InDesiredState = $false
                    Write-Verbose -Message ($LocalizedData.VerboseTestTargetSetting -f $setting.Name )
                }
            }
        }
       
        <#
        $capSettings = Get-childItem $capItem.PSPath
        $itemPath = $capSettings[0].ParentPath

        if($PSBoundParameters.ContainsKey('Status') -and ($capSettings | Where Name -eq Status).CurrentValue -ne $Status)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetSetting -f "Status" )
        }
        
        if($PSBoundParameters.ContainsKey('AuthMethod') -and ($capSettings | Where Name -eq AuthMethod).CurrentValue -ne $AuthMethod)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetSetting -f "Authmethod" )
        }
  
        if($PSBoundParameters.ContainsKey('IdleTimeout') -and ($capSettings | Where Name -eq IdleTimeout).CurrentValue -ne $IdleTimeout)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetSetting -f "IdleTimeout" )
        }
          
        if($PSBoundParameters.ContainsKey('SessionTimeout') -and ($capSettings | Where Name -eq SessionTimeout).CurrentValue -ne $SessionTimeout)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetSetting -f "SessionTimeout" )
        }
          
        if($PSBoundParameters.ContainsKey('SessionTimeoutAction') -and ($capSettings | Where Name -eq SessionTimeoutAction).CurrentValue -ne $SessionTimeoutAction)
        {
            $InDesiredState = $false
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetSetting -f "SessionTimeoutAction" )
        }
        #>

        if($PSBoundParameters.ContainsKey('Usergroups'))
        {
            $userGroupPath = ('{0}\{1}' -f $itemPath, "UserGroups")
            $currentGroups = Get-ChildItem -Path $userGroupPath
            $compareGroups = Compare-Object -ReferenceObject $userGroups -DifferenceObject $currentGroups
            if($compareGroups -ne $null)
            {
                $InDesiredState = $false
                $compareGroups | where SideIndicator -eq '=>' | ForEach {
                    Write-Verbose -Message ($LocalizedData.VerboseTestTargetUsergroupRemoveAuthorization -f $_.InputObject)
                }
                $compareGroups | where SideIndicator -eq '<=' | ForEach {
                    Write-Verbose -Message ($LocalizedData.VerboseTestTargetUsergroupAddAuthorization -f $_.InputObject)
                }
            }
        } 
    
    }
    if ($InDesiredState -eq $true) 
    { 
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetTrueResult) 
    } 
    else 
    { 
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseResult) 
    } 
    return $InDesiredState 
}


Export-ModuleMember -Function *-TargetResource

