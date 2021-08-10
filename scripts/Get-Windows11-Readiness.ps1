<#
    .SYNOPSIS
    Windows 10 Software packaging wrapper
    .DESCRIPTION
    Install:   PowerShell.exe -ExecutionPolicy Bypass -Command .\Get-Windows-Readiness.ps1
    .ENVIRONMENT
    PowerShell 5.0
    .AUTHOR
    Niklas Rast
    .REQUIREMENTS
    https://docs.microsoft.com/en-us/windows-hardware/design/minimum/minimum-hardware-requirements-overview
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory = $false, HelpMessage = 'Provide your Teams Channel URL here')]
  [string]$TeamsChannelUrl
)

$ErrorActionPreference = "SilentlyContinue"

function InformIT {
  param (
    [string]$message,
    [string]$color
  )
  $JSONBody = [PSCustomObject][Ordered]@{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "summary"    = "$ENV:COMPUTERNAME"
    "themeColor" = "$color"
    "title"      = "$ENV:COMPUTERNAME"
    "text"       = $message
  }

  $TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100
  Invoke-RestMethod -Uri $TeamsChannelUrl -Method Post -Body $TeamMessageBody -ContentType 'application/json'
}

$Models = Get-Content -Path "$PSSCRIPTROOT\processors.csv" | convertfrom-csv -Header Manafacturer, series, model
$Proc = (Get-CimInstance -ClassName Win32_Processor).name -split ' ' | ForEach-Object { $models | Where-Object -Property model -eq $_ }
$Ram = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object { [Math]::Round(($_.sum / 1GB), 2) }) -gt 4
$Disk = ((Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace, VolumeName | Where-Object DeviceID -Match 'C:').size) -gt 68719476736
#$BiosMode = (Confirm-SecureBootUEFI -ErrorVariable ProcessError)

$Results = [PSCustomObject]@{
  "Hostname"             = [Environment]::MachineName
  "TPM Compatible"       = [bool](Get-Tpm).tpmpresent
  "Processor Compatible" = [bool]$Proc
  #"UEFI Compatible"      = [bool]$BiosMode
  "64 Bit OS"            = [Environment]::Is64BitOperatingSystem
  "Minimum 4GB RAM"      = [bool]$Ram
  "Minimum 64GB HDD"     = [bool]$Disk
}

if ($results.psobject.properties.value -contains $false) {
  Write-Host "This device is not compatible with Windows 11" -ForegroundColor Red
  $Results | Format-List #| Out-File C:\Windows\Logs\Windows11Readiness.log

  if ($TeamsChannelUrl -ne $null) { InformIT -message "The device $ENV:COMPUTERNAME is NOT compatible to run Windows 11, $results" -color "d73b00" }
}
else {
  Write-Host "This device is compatible with Windows 11" -ForegroundColor Green
  $Results | Format-List #| Out-File C:\Windows\Logs\Windows11Readiness.log

  if ($TeamsChannelUrl -ne $null) { InformIT -message "The device $ENV:COMPUTERNAME is compatible to run Windows 11, $results" -color "0bd700" }
}
