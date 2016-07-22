[CmdletBinding()]
param(
)

$installPath = .\Get-CiscoVpnPath.ps1 -ErrorAction Stop

$status = .\Get-CiscoVpnStatus.ps1

if ($status.Connected) {
	$outputLines = @()
	& "$($installPath)\vpnclient.exe" disconnect | foreach { $outputLines += $_ }
	$status = .\Get-CiscoVpnStatus.ps1
	if ($status.Connected) {
		$outputLines | foreach { Write-Host $_ }
		Write-Error "Unable to disconnect from '$($status.ConnectionEntry)'."
	}
} else {
	Write-Verbose "Not currently connected."
}
