[CmdletBinding()]
param(
    [parameter(Mandatory=$True)]
    [string]
    $Location,

    [parameter(Mandatory=$True)]
    [string]
    $SubscriptionId,

    [ValidateSet("ExpressRoute", "VPN")]
    [parameter(Mandatory=$True)]
    [string]
    $GatewayType,

    [parameter(Mandatory=$True)]
    [ValidateSet("1", "2", "3","All")]
    [string]
    $Zone,

    [parameter(Mandatory=$True)]
    [string]
    $Name
)

Function Test-LoginAzureRmAccount {
    Write-Host "Checking to see if you need to log in... " -NoNewline
    $captured = Get-AzureRmSubscription
    if ($null -eq $captured) {
        Login-AzureRmAccount
    } else {
        Write-Host "No need to Login-AzureRmAccount!" -ForegroundColor 'Green'
    }
}

$resourceGroup = $null
if ($Zone -eq "All") {
	$resourceGroup = "ZonalResilientGateway-$Name"
} else {
	$resourceGroup = "ZonalGateway-$Name"
}

$GWName = "GW-$name"
$GWIPconfName = "Gwipconf-$name"
$VNetName = "vnet-$name"
$AddressPrefixGW = "10.1.1.0/26"
$AddressPrefixVnet = "10.1.0.0/16"
$placement = @{
    ResourceGroupName = $resourceGroup;
    Location = $location
}
Test-LoginAzureRmAccount -SubscriptionId $SubscriptionId
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

New-AzureRmResourceGroup -Location $location -Name $resourceGroup -Force


$allowOutbound = New-AzureRmNetworkSecurityRuleConfig -Name 'all-out' -Description "All out" `
-Access Allow -Protocol * -Direction Outbound -Priority 100 -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange * -SourceAddressPrefix * ;

$gatewayPorts = @(8080,8443,8081,20000,443,10001,10002,179,4500,8082,65330,3389)
$startingPriority = 100
$inboundRules = $gatewayPorts | % { New-AzureRmNetworkSecurityRuleConfig -Name "inbound-$_"  `
-Description "All inbound on port $_" -Priority $startingPriority `
-Access Allow -Protocol * -Direction Inbound -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange $_ -SourceAddressPrefix * ; $startingPriority = $startingPriority + 1 }

$nsg = New-AzureRmNetworkSecurityGroup @placement -Name "NSG-FrontEnd" -SecurityRules ($inboundRules + $allowOutbound)

$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -AddressPrefix $AddressPrefixGW `
    -NetworkSecurityGroup $nsg 
$subnet

Write-Host 'Creating Vnet'
$vnet = New-AzureRmVirtualNetwork @placement -Name $VNetName -AddressPrefix $AddressPrefixVnet `
    -Subnet $subnet

$vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $resourceGroup
$vnet

$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet
$subnet

$GWIPName1 = "GWLBPIP"
$pip = $null
if ($Zone -eq "All") {
	$pip = New-AzureRmPublicIpAddress @placement -Name $GWIPName1 `
    -AllocationMethod Static -Sku Standard
} else {
	$pip = New-AzureRmPublicIpAddress @placement -Name $GWIPName1 `
    -AllocationMethod Static -Sku Standard -Zone $Zone
}
$pip

$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName `
    -Subnet $subnet -PublicIpAddress $pip
$ipconf

Write-Host "Creating Gateway"
switch ($GatewayType) {
    "ExpressRoute" {
        Get-Date -Format g
        $gw = New-AzureRmVirtualNetworkGateway @placement -Name $GWName `
            -IpConfigurations $ipconf -GatewayType ExpressRoute `
            -GatewaySku HighPerformance
        $gw
        Get-Date -Format g
    }
    "VPN" {
        Get-Date -Format g
        $gw = New-AzureRmVirtualNetworkGateway @placement -Name $GWName `
            -IpConfigurations $ipconf -GatewayType Vpn `
            -GatewaySku VpnGw3 -VpnType RouteBased
        $gw
        Get-Date -Format g
    }
}
Write-Host "Done!"