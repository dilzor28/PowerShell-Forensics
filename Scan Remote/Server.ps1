## Server Listener to listen for hosts responding  ##

## Use in conjunction with Host.ps1                ##

$Outfile = "C:\ListOfSystems.txt"
$IP = "192.168.1.54"

# Initialize socket and bind
$ICMPSocket = New-Object System.Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork,[Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Icmp)
$Address = New-Object system.net.IPEndPoint([system.net.IPAddress]::Parse($IP), 0) 
$ICMPSocket.bind($Address)
$ICMPSocket.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
$buffer = new-object byte[] $ICMPSocket.ReceiveBufferSize

# Set Capture to false

while($True)
{
        #Only inspect the request packets - type 8
        # Request
        if([System.BitConverter]::ToString($buffer[20]) -eq "08")
        {
            #IF EOF is received in data segment of ICMP the script will exit the loop.
            if([System.Text.Encoding]::ASCII.GetString($buffer[28..30]) -eq "EOF")
            {
                Write-Output "EOF received - transfer complete - Saving file and stopping script"
                #create file 
                [System.Text.Encoding]::ASCII.GetString($Transferbytes) | Out-File $Outfile
                $Capture = $false
                break
            } 
            
            
            # Byte 28 = BOF
            if([System.Text.Encoding]::ASCII.GetString($buffer[28..30]) -eq "BOF")
            {
                #BOF MATCH
                Write-Output "BOF received - Starting Capture of data"
				$Content = [System.Text.Encoding]::ASCII.GetString($buffer[31..80])
				[byte[]]$Transferbytes += $content
                $Capture = $true
            } 
        }
        $null = $ICMPSocket.Receive($buffer)
}