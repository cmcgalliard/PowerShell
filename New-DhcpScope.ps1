function New-DhcpScope 
{
<#
.SYNOPSIS
This script Adds DHCP Scopes to the Windows DHCP Environment
#>

###########################################
###
###      Define Parmaters 
###
###########################################

[cmdletbinding()]
Param(
[Parameter(Position=0, HelpMessage="DHCP Scope Name", mandatory=$true)]
$ScopeName, 
[Parameter(Position=1, HelpMessage="DHCP Scope Start IP Address", mandatory=$true)]
$Start, 
[Parameter(Position=2, HelpMessage="DHCP Scope End IP adress", mandatory=$true)]
$End, 
[Parameter(Position=3, HelpMessage="DHCP Scope Subnet Mask", mandatory=$true)]
$SubnetMask, 
[Parameter(Position=4, HelpMessage="DHCP Scope Router IP Address", mandatory=$true)]
$Router, 
[Parameter(HelpMessage="DHCP Scope DNS Settings. 1 = Domain DNS (Default), 2 = Google DNS", mandatory=$false)]
$DNS, 
[Parameter(HelpMessage="DHCP Scope Reservation Lease Duration (In hours, 8 hours are default)", mandatory=$false)]
$Time, 
[Parameter(HelpMessage="DHCP Option 42 settings - Enter 'unifi' or 'cisco'.", mandatory=$false)]
$Wifi,
[Parameter(HelpMessage="DHCP Server Name (Default to cuvutility)", mandatory=$false)]
$DhcpServer
)

###########################################
###
###       setup Default values and strings
###
###########################################
$GoogleDNS = "8.8.8.8"
$DNS1 = "10.1.1.2"
$DNS2 = "10.1.1.3"
$DefaultHours = 8
$DefaultDHCPServer = "dhcpsvr"
$DomainName = "domain.local"

if(!$DhcpServer)    {$DhcpServer = $DefaultDHCPServer}
if ($DNS -eq 2)     {$DNS = $GoogleDNS}
if ($DNS -eq 1)     {$DNS = $DNS1, $DNS2}
if (!$DNS)          {$DNS = $DNS1, $DNS2}
if(!$Time)          {$time = $DefaultHours}

$timespan=New-TimeSpan -Hours $Time
$scopeid=$start.substring(0,$start.Length-1)+"0"

###########################################
###
###       Heavy Lifting
###
###########################################

Add-DhcpServerv4Scope -ComputerName $DhcpServer -name $ScopeName -StartRange $Start -EndRange $End -State Active -SubnetMask $SubnetMask -LeaseDuration $timespan
Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 003 -Value $Router
Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 006 -Value $DNS
Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 015 -Value $DomainName
Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 044 -Value $DNS1
Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 046 -Value "0x8"
if($wifi -eq 'unifi') {Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 043 -Value 0x01,0x04,0x0a,0x0a,0x0a,0x36}
if($wifi -eq 'cisco') {Set-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $scopeid -OptionId 043 -Value 0x01,0x04,0x0a,0x0a,0x0a,0x36}

###########################################
###
###       Validation
###
###########################################

Get-DhcpServerv4Scope -ComputerName $DhcpServer -ScopeId $scopeid
Get-DhcpServerv4OptionValue -ScopeId  $scopeid -ComputerName $DhcpServer -all | Select-Object Name, OptionID, Value
}


