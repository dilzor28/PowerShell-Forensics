## Send this to the remote systems to run                ##
## This will only send out if the ransomware is detected ##
## Use in conjunction with Server.ps1					 ##

$filename = "" # File to scan remote host for

$malware = Get-ChildItem -Path $env:HOMEDRIVE\Users -Filter $filename -Recurse -ErrorAction SilentlyContinue | %{$_.FullName}

if ($malware){
	# Gathering system information
	$ipv4 = Test-Connection -ComputerName (hostname) -Count 1  | Select IPV4Address
	$ipv4 = $ipv4.IPV4Address.IPAddressToString
	$osVersion = [environment]::OSVersion.Version
	$windowsVersion = $osVersion.Major
	$windowsBuild = $osVersion.Build
	$osVersion = "$($windowsVersion).$($windowsBuild)"
	$infoToSend = "$env:COMPUTERNAME | $($ipv4) | $($osVersion)"

	# Configuration for ICMP requests
	$IPAddress = "" # Add IP address to ping
	$ICMPClient = New-Object System.Net.NetworkInformation.Ping
	$PingOptions = New-Object System.Net.NetworkInformation.PingOptions
	$PingOptions.DontFragment = $true
	
	
	# Start of Transfer
	$sendbytes = ([text.encoding]::ASCII).GetBytes("INFECTED HOST | " + $infoToSend + " | ")
	$ICMPClient.Send($IPAddress,10, $sendbytes, $PingOptions) | Out-Null
	}
