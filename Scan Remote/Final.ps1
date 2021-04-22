# Configuration for ICMP requests
# Test file, not used

$IPAddress = "" # Add IP address to ping
$ICMPClient = New-Object System.Net.NetworkInformation.Ping
$PingOptions = New-Object System.Net.NetworkInformation.PingOptions
$PingOptions.DontFragment = $true


# Ends the Listener
$sendbytes = ([text.encoding]::ASCII).GetBytes("EOF")
$ICMPClient.Send($IPAddress,10, $sendbytes, $PingOptions) | Out-Null
