[CmdletBinding()]
param(
	[Parameter(Mandatory=$true, HelpMessage="The name of the profile to connect.")]
	[string]$Name
)

$installPath = .\Get-CiscoVpnPath.ps1 -ErrorAction Stop

.\Get-CiscoVpnProfile.ps1 -Name $Name -ErrorAction Stop | Out-Null

$status = .\Get-CiscoVpnStatus.ps1

if ($status.Connected) {
	if ($status.ConnectionEntry -eq $Name) {
		Write-Host "Already connected to '$($Name)'."
		return
	}

	Write-Host "Disconnecting from '$($status.ConnectionEntry)'..."
	.\Disconnect-CiscoVpn.ps1
}

$outputLines = @()
& "$($installPath)\vpnclient.exe" connect $Name | foreach {
	$outputLines += $_
}

$status = .\Get-CiscoVpnStatus.ps1

if (-not($status.Connected)) {
	$outputLines | foreach {
		Write-Host $_
	}
	Write-Error "Connect failed."
}
