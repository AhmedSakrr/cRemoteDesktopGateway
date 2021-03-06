# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
VerboseTestTargetMaxConnectionsNoMatch = MaxConnections does not match the current value.
VerboseTestTargetSSLBridgingNoMatch = SSLBridging does not match the current value.
VerboseTestTargetEnableOnlyMessagingCapableClientsNoMatch = EnableOnlyMessagingCapableClients does not match the current value.
VerboseTestTargetCentralCAPEnabledNoMatch = CentralCAPEnabled does not match the current value.
VerboseTestTargetRequestSOHNoMatch = RequestSOH does not match the current value.
VerboseTestTargetConfigurationNoMatch = Reference configuration does not match the current configuration.
VerboseTestTargetTrueResult = The target resource is already in the desired state. No action is required. 
VerboseTestTargetFalseResult = The target resource is not in the desired state. 
VerboseSetTargetMaxConnections = MaxConnections is set to {0}.
VerboseSetTargetRequestSOH = RequestSOH is set to {0}.
VerboseSetTargetCentralCAPEnabled = CentralCAPEnabled is set to {0}.
VerboseSetTargetSSLBridging = SSLBridging is set to {0}.
VerboseSetTargetEnableOnlyMessagingCapableClients = EnableOnlyMessagingCapableClients is set to {0}.
'@

}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [System.String]
        $MaxConnections = 4294967295,

        [ValidateSet("0","1")]
        [System.String]
        $RequestSOH = 1,

        [parameter(Mandatory = $true)]
        [ValidateSet("0","1")]
        [System.String]
        $CentralCAPEnabled = 0,

        [ValidateSet("0","1","2")]
        [System.String]
        $SSLBridging = 0,

        [ValidateSet("0","1")]
        [System.String]
        $EnableOnlyMessagingCapableClients = 0
    )

    $returnValue = @{
    MaxConnections = [System.String](Get-Item -Path RDS:\GatewayServer\MaxConnections | Select-Object -ExpandProperty CurrentValue)
    CentralCAPEnabled = [System.String](Get-Item -Path RDS:\GatewayServer\CentralCAPEnabled | Select-Object -ExpandProperty CurrentValue)
    RequestSOH = [System.String](Get-Item -Path RDS:\GatewayServer\RequestSOH | Select-Object -ExpandProperty CurrentValue)
    SSLBridging =  [System.String](Get-Item -Path RDS:\GatewayServer\SSLBridging | Select-Object -ExpandProperty CurrentValue)
    EnableOnlyMessagingCapableClients =  [System.String](Get-Item -Path RDS:\GatewayServer\EnableOnlyMessagingCapableClients | Select-Object -ExpandProperty CurrentValue)
    }
    Write-Debug $returnValue


    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [System.String]
        $MaxConnections = 4294967295,

        [ValidateSet("0","1")]
        [System.String]
        $RequestSOH = 1,

        [parameter(Mandatory = $true)]
        [ValidateSet("0","1")]
        [System.String]
        $CentralCAPEnabled = 0,

        [ValidateSet("0","1","2")]
        [System.String]
        $SSLBridging = 0,

        [ValidateSet("0","1")]
        [System.String]
        $EnableOnlyMessagingCapableClients = 0
    )
    
    if((Get-Item -Path RDS:\GatewayServer\MaxConnections | Select-Object -ExpandProperty CurrentValue) -ne $MaxConnections)
    {
        Set-Item -Path RDS:\GatewayServer\MaxConnections -Value $MaxConnections
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetMaxConnections -f $MaxConnections)
    }

    if((Get-Item -Path RDS:\GatewayServer\RequestSOH | Select-Object -ExpandProperty CurrentValue) -ne $RequestSOH)
    {
        Set-Item -Path RDS:\GatewayServer\RequestSOH -Value $RequestSOH
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetRequestSOH -f $RequestSOH)
    }
    
    if((Get-Item -Path RDS:\GatewayServer\CentralCAPEnabled | Select-Object -ExpandProperty CurrentValue) -ne $CentralCAPEnabled)
    {
        Set-Item -Path RDS:\GatewayServer\CentralCAPEnabled -Value $CentralCAPEnabled
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetCentralCAPEnabled -f $CentralCAPEnabled)
    }

    if((Get-Item -Path RDS:\GatewayServer\SSLBridging | Select-Object -ExpandProperty CurrentValue) -ne $SSLBridging)
    {
        Set-Item -Path RDS:\GatewayServer\SSLBridging -Value $SSLBridging
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetSSLBridging -f $SSLBridging)
    }

    if((Get-Item -Path RDS:\GatewayServer\EnableOnlyMessagingCapableClients | Select-Object -ExpandProperty CurrentValue) -ne $EnableOnlyMessagingCapableClients)
    {
        Set-Item -Path RDS:\GatewayServer\EnableOnlyMessagingCapableClients -Value $EnableOnlyMessagingCapableClients
        Write-Verbose -Message ($LocalizedData.VerboseSetTargetEnableOnlyMessagingCapableClients -f $EnableOnlyMessagingCapableClients)
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [System.String]
        $MaxConnections = 4294967295,

        [ValidateSet("0","1")]
        [System.String]
        $RequestSOH = 1,

        [parameter(Mandatory = $true)]
        [ValidateSet("0","1")]
        [System.String]
        $CentralCAPEnabled = 0,

        [ValidateSet("0","1","2")]
        [System.String]
        $SSLBridging = 0,

        [ValidateSet("0","1")]
        [System.String]
        $EnableOnlyMessagingCapableClients = 0
    )
    Assert-Module
    $targetResource = Get-TargetResource @PSBoundParameters
    $InDesiredState = $true
      
    if($MaxConnections -ne $targetResource.MaxConnections)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetMaxConnectionsNoMatch)
        $InDesiredState = $false   
    }
      
    if($CentralCAPEnabled -ne $targetResource.CentralCAPEnabled)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetCentralCAPEnabledNoMatch)
        $InDesiredState = $false   
    }

    if($RequestSOH -ne $targetResource.RequestSOH)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetRequestSOHNoMatch)
        $InDesiredState = $false   
    }

    if($SSLBridging -ne $targetResource.SSLBridging)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetSSLBridgingNoMatch)
        $InDesiredState = $false   
    }

    if($EnableOnlyMessagingCapableClients -ne $targetResource.EnableOnlyMessagingCapableClients)
    {
        Write-Verbose -Message ($LocalizedData.VerboseTestTargetEnableOnlyMessagingCapableClientsNoMatch)
        $InDesiredState = $false   
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

