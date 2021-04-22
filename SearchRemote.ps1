#########################################################################
### Run this script from a DC or domain admin account                 ###
### Put this script, SearchStarter.ps1, and PSExec.exe on the Desktop ###
#########################################################################

# This is the powershell script deployed to end hosts which will search IOCs


New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
$iocs = ""

# Fill in for IOCs that were found

#$regPropertyName = PROPERTY_FOUND
$filename = "RECOVER-FILES.txt"
#$fileExtensions = RANSOMWARE_UNIQUE_EXTENSIONS

# Change the path as necessary for the registry IOCS
$hklmRunKey = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

### THIS IS A TEST SEARCH FOR RUN KEYS ###
#if($hklmRunKey.PSObject.Properties.Name -Match $regPropertyName) {
#	$iocs += "$regpropertyName | "
#}

### THIS IS A TEST SEARCH FOR RUN KEYS ###
#$userSids = (Get-ChildItem -Path HKU:\ | Where ($_.Name -notmatch "Classes")
#foreach($sid in userSids){
#	$userRunKey = Get-ItemProperty -Path "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Run"
#	if ($userRunKey.PSObject.Properties.Name -Match $regPropertyName) {
#		$iocs += "$regPropertyName | "
#	}
#}


# Change the path to a little more specific to quicken search time
$files = Get-ChildItem -Path $env:HOMEDRIVE\Users -Filter $filename -Recurse -ErrorAction SilentlyContinue | %{$_.FullName}

# MAKE SURE FILENAME WAS SET ABOVE
if ($files) {
	foreach ($file in $files){
	$iocs += "$file | "
	}
}

#$extensions = Get-ChildItem -Path $env:HOMEDRIVE -Filter *.$extensions -Recurse -ErrorAction SilentlyContinue | %{$_.FullName}

#if ($extensions) {
#	foreach ($file in $extensions) {
#		$iocs += "$file | "
#	}
#}


return $iocs