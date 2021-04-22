#########################################################################
### Run this script from a DC or domain admin account                 ###
### Put this script, SearchRemote.ps1, and PSExec.exe on the Desktop  ###
#########################################################################


$psexecPath = "C:\Users\Administrator\Desktop\PsExec.exe"
$searchScriptPath = "C:\Users\Administrator\Desktop\SearchRemote.ps1"
$outputPath = "C:\Users\Administrator\Desktop\results.csv"

$listOfComputers = Get-ADComputer -Filter * -properties ipv4Address, OperatingSystem, OperatingSystemServicePack
foreach ($computer in $listOfComputers) {
	$ip = $computer.IPv4Address
	$name = $computer.Name
	if (-not (Test-Path "\\$ip\c$")) {
        $computer | Add-Member -NotePropertyName IOCs_Found -NotePropertyValue "COULD NOT REACH" -Force
        continue
        }
	Copy-Item $searchScriptPath "\\$ipc\c$\"
	if (Test-WSMan $name){
		$iocs = Invoke-Command -ComputerName $name -ScriptBlock {powershell -ExecutionPolicy Bypass -File C:\SearchRemote.ps1
		}
	}
	else {
		$iocs = Invoke-Expression "$psexecPath -nobanner -accepteula `"\\$ip`" powershell -ExecutionPolicy Bypass -File C:\SearchRemote.ps1"
	}
	Remove-Item "\\$ip\c$\SearchRemote.ps1"
	$computer | Add-Member -NotePropertyName IOCs_Found -NotePropertyValue $iocs -Force
}

$listOfComputers | Export-Csv -NoTypeInformation -Path $outputPath