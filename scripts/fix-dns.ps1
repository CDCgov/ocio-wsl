###########################################################################
## Problem:
## Windows Subsystem Linux (WSL) Linux distros set its own DNS resolver
## settings on startup of the image. It resolves it wrong, and people have
## complained of a fix: https://gist.github.com/coltenkrauter/608cfe02319ce60facd76373249b8ca6
##
## Ideally, the DNS resolver should use your home router (Gateway IP) as
## the resolver, and your home router will figure out DNS based on the
## corporate network's configuration or public network configuration.
##
## Solution:
## This is a script copied from to fix this issue by figuring out
## the proper IP address we should use.
## https://gist.github.com/ThePlenkov/6ecf2a43e2b3898e8cd4986d277b5ecf
## This script fixes DNS for an initially starting image in WSL.
##
## Usage:
## powershell -executionpolicy bypass -File fix-dns.ps1 <distro_name>
##
###########################################################################
param (
  [string]$distroName
)

if (-not $distroName) {
  Write-Host "Distro name cannot be empty. Please provide a valid distro name."
  return
}

if ($distroName -match '[\\/:*?"<>|]') {
  Write-Host "Invalid characters detected in the distro name. Please provide a valid distro name."
  return
}

############################################################################
## Powershell makes it a pain to write a file that is Unix compliant 
## namely, no \r\n carriage return (Unix use \n), and UTF8 No BOM Encoding
## 
## This method writes the /etc/resolv.conf file twice (a tad inefficient), in 
## order to write the proper file.
##
## You can compare the file written by Unix and by Windows matching it
## byte by byte using the command - od -t x1 /etc/resolv.conf
## 
## If you see the following HEX
## 0d 0a means Windows carriage return '\r\n', Unix files do not have this.
## 0a is the normal '\n' return, Unix file can have this.
## ef bb bf is the byte order mark (BOM), Unix files do not have this.
############################################################################
$DNSList = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses
$DNSFile = "\\wsl$\$distroName\etc\resolv.conf"
foreach ($DNS in $DNSList) {
  $command = "wsl -d $distroName echo -e 'nameserver $DNS' 2>&1 | % ToString | Out-File -FilePath $DNSFile -Encoding UTF8 -NoNewLine"
  Invoke-Expression $command
}

$RawString = Get-Content -Raw $DNSFile
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText($DNSFile, $RawString, $Utf8NoBomEncoding)

Write-Host "DNS resolution has been updated for $distroName."