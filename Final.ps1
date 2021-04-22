# Configuration for ICMP requests
$IPAddress = "192.168.1.54"
$ICMPClient = New-Object System.Net.NetworkInformation.Ping
$PingOptions = New-Object System.Net.NetworkInformation.PingOptions
$PingOptions.DontFragment = $true


# Ends the Listener
$sendbytes = ([text.encoding]::ASCII).GetBytes("EOF")
$ICMPClient.Send($IPAddress,10, $sendbytes, $PingOptions) | Out-Null
