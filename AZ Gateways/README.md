# Zone Redundant Azure VPN and Express Route Gateways
This repo hosts example PowerShell scripts and documentation for deploying Azure VPN and Express Route Zone Redundant gateways.

# Sample Usage

# Example 1
DeployZonalGateway.ps1 -Location eastus2euap -GatewayType VPN -SubscriptionId "" -Zone 1 -Name MyAZGW

This will deploy VPN gateway in East US2 EUAP region.  Both instances of the VPN gateway will be deployed in Zone 1.

# Example 2
DeployZonalGateway.ps1 -Location eastus2euap -GatewayType VPN -SubscriptionId "" -Zone All -Name MyAZGW

This will deploy VPN gateway in East US2 EUAP region.  Thw two instances will be deployed in 2 different zones (any two out of 1, 2, 3).

# Request Access
At this point in time, the access to creating Zone-Redundant gateways in under limited access.   Please drop an email to 'AZ Network Gateways Onboarding <aznetworkgateways@microsoft.com>' and we will notify you when the access becomes opens for you.