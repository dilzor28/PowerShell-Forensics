########################################################################
########################################################################
###   This file is designed to determine the mounted location and    ###
###   evidence control number for a forensics case and will begin    ###
###   to capture a triaged version of the image                      ###
########################################################################
########################################################################
###     Made by dilzor28 with help from sustainablelobster and       ###
###     merrillmatt011 with additional code stolen from Chris Wu     ###
########################################################################
########################################################################


###   ISO will be created on running user's desktop                  ###


### This function is designed to capture an iso from a folder
function New-IsoFile {  
  <#  
   .Synopsis  
    Creates a new .iso file  
   .Description  
    The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders  
   .Example  
    New-IsoFile "c:\tools","c:Downloads\utils"  
    This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of the .iso image.  
   .Example 
    New-IsoFile -FromClipboard -Verbose 
    Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.  
   .Example  
    dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE" 
    This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx  
   .Notes 
    NAME:  New-IsoFile  
    AUTHOR: Chris Wu 
    LASTEDIT: 03/23/2016 14:46:50  
 #>  
  
  [CmdletBinding(DefaultParameterSetName = 'Source')]Param( 
    [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Source')]$Source,  
    [parameter(Position = 2)][string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",  
    [ValidateScript( { Test-Path -LiteralPath $_ -PathType Leaf })][string]$BootFile = $null, 
    [ValidateSet('CDR', 'CDRW', 'DVDRAM', 'DVDPLUSR', 'DVDPLUSRW', 'DVDPLUSR_DUALLAYER', 'DVDDASHR', 'DVDDASHRW', 'DVDDASHR_DUALLAYER', 'DISK', 'DVDPLUSRW_DUALLAYER', 'BDR', 'BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER', 
    [string]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),  
    [switch]$Force, 
    [parameter(ParameterSetName = 'Clipboard')][switch]$FromClipboard
  ) 
 
  Begin {  
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
    if (!('ISOFile' -as [type])) {  
      Add-Type -CompilerParameters $cp -TypeDefinition @' 
public class ISOFile  
{ 
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)  
  {  
    int bytes = 0;  
    byte[] buf = new byte[BlockSize];  
    var ptr = (System.IntPtr)(&bytes);  
    var o = System.IO.File.OpenWrite(Path);  
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
  
    if (o != null) { 
      while (TotalBlocks-- > 0) {  
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);  
      }  
      o.Flush(); o.Close();  
    } 
  } 
}  
'@  
    } 
  
    if ($BootFile) { 
      if ('BDR', 'BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" } 
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type = 1 }).Open()  # adFileTypeBinary 
      $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname) 
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream) 
    } 
 
    $MediaType = @('UNKNOWN', 'CDROM', 'CDR', 'CDRW', 'DVDROM', 'DVDRAM', 'DVDPLUSR', 'DVDPLUSRW', 'DVDPLUSR_DUALLAYER', 'DVDDASHR', 'DVDDASHRW', 'DVDDASHR_DUALLAYER', 'DISK', 'DVDPLUSRW_DUALLAYER', 'HDDVDROM', 'HDDVDR', 'HDDVDRAM', 'BDROM', 'BDR', 'BDRE') 
 
    Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))" 
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName = $Title }).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media)) 
  
    if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break } 
  }  
 
  Process { 
    if ($FromClipboard) { 
      if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break } 
      $Source = Get-Clipboard -Format FileDropList 
    } 
 
    foreach ($item in $Source) { 
      if ($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { 
        $item = Get-Item -LiteralPath $item 
      } 
 
      if ($item) { 
        Write-Verbose -Message "Adding item to the target image: $($item.FullName)" 
        try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') } 
      } 
    } 
  } 
 
  End {  
    if ($Boot) { $Image.BootImageOptions = $Boot }  
    $Result = $Image.CreateResultImage()  
    [ISOFile]::Create($Target.FullName, $Result.ImageStream, $Result.BlockSize, $Result.TotalBlocks) 
    Write-Verbose -Message "Target image ($($Target.FullName)) has been created" 
    $Target 
  } 
}

# Configure the powershell policy to run unsigned scripts
$OriginalExecutionPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force


# Do not display errors to the screen
$OriginalErrorPolicy = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

# Get the mounted location of the evidence and ensure it is 1 letter
do { 
  $mounted_location = Read-Host -Prompt 'Where did you mount the evidence?'
} until (($mounted_location.Length -eq 1) -and ($mounted_location.ToLower() -match "[a-z]{1}"))
$mounted_location = $mounted_location.ToUpper() + ':\'


# Case Number associated with the evidence
do { 
  $ecn = Read-Host -Prompt 'What is the case number for this evidence? (YYYY-DDDD format)'
} until ($ecn -match "\d{4}-\d{4}")

# Append 'root' to home directory if mounted with FTK Imager
$error_validation = Get-ChildItem -Path $mounted_location -Name -Attributes Directory, System, Archive, Hidden, ReadOnly
$root = 'root'

foreach ($item in $error_validation) {
  if ($item -match 'root') {
    $mounted_location += $item
  }
  else {
    $mounted_location = $mounted_location
  }
}

# Location where to save the temporary triage image files on the host system
$export_path = $env:USERPROFILE + '\Desktop\Triage_Image_' + $ecn + '\'

if (!(Test-Path $export_path)) {
  New-Item -ItemType Directory -Force -Path $export_path
}

$TriageFileLocations = '.\TriageFileLocations.txt'
$TriageDirectoryLocations = '.\TriageDirectoryLocations.txt'

# Make the export directory if the evidence file exists and copy the files into it
# while maintaining the original TimeStamps
Get-Content $TriageFileLocations | Foreach-Object { if (Test-Path $mounted_location$_) {
    $source_file = $mounted_location + $_
    $copied_file = New-Item -Name ((Get-ItemProperty $source_file).Directory.FullName.TrimStart($mounted_location)) -Path $export_path -ItemType "Directory"
    (Get-ItemProperty $copied_file).CreationTime = (Get-ItemProperty $source_file).CreationTime
    (Get-ItemProperty $copied_file).LastAccessTime = (Get-ItemProperty $source_file).LastAccessTime
    (Get-ItemProperty $copied_file).LastWriteTime = (Get-ItemProperty $source_file).LastWriteTime
  }
}

Get-Content $TriageFileLocations | Foreach-Object { if (Test-Path $mounted_location$_) {
    $source_file = $mounted_location + $_
    Copy-Item -Path $source_file -Destination $export_path$_ -Force
    (Get-ItemProperty -Path "$export_path$_").CreationTime = (Get-ItemProperty -Path $source_file).CreationTime
    (Get-ItemProperty -Path "$export_path$_").LastWriteTime = (Get-ItemProperty -Path $source_file).LastWriteTime
    (Get-ItemProperty -Path "$export_path$_").LastAccessTime = (Get-ItemProperty -Path $source_file).LastAccessTime    
  }
}

# Copy the evidence directories of significance and preserve timestamps

Get-Content $TriageDirectoryLocations | Foreach-Object { if (Test-Path $mounted_location$_) {
    $source_dir = $mounted_location + $_
    $destination_dir = $export_path
    #Copy-Item -Path $source_dir -Destination $destination_dir -Recurse -Force
    
    foreach ($item in (Get-ChildItem -Path $source_dir -Recurse -Force)) {
      $file = ($item.FullName).Split(":")[1]
      Copy-Item -Path $item.FullName -Destination "$export_path$file"
      (Get-ItemProperty -Path "$export_path$file").CreationTime = $item.CreationTime
      (Get-ItemProperty -Path "$export_path$file").LastWriteTime = $item.LastWriteTime
      (Get-ItemProperty -Path "$export_path$file").LastAccessTime = $item.LastAccessTime
    }
  }
}

# Now to take a Triaged image of the evidence
$year = ($ecn -Split "-")[0]

[int]$number = ($ecn -split "-")[1]
New-IsoFile $export_path "$env:USERPROFILE\Desktop\Triage_$ecn.iso" 

# Set error policy back to what it initially was
$ErrorActionPreference = $OriginalErrorPolicy

# Remove the saved files since the triage image is done and iso copied
Remove-Item -Path $export_path -Recurse -Force

#Set the Powershell signed scripts policy back to default
Set-ExecutionPolicy -ExecutionPolicy $OriginalExecutionPolicy -Force
