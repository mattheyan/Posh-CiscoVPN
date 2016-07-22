param(
	[Parameter(Mandatory=$true, HelpMessage="The name of the profile to connect.")]
	[string]$Name
)

. .\__init__.ps1

EnsureInstalled
EnsureProfile -Name $Name

$stat = .\Get-VPNStatus.ps1

if ($stat.Connected) {
	if ($stat.ConnectionEntry -eq $Name) {
		write-host "Already connected to $Name." -ForegroundColor Yellow
		return
	}
	
	write-host "Disconnecting from $($stat.ConnectionEntry)..." -ForegroundColor Yellow
	.\Disconnect-VPN.ps1
}

$result = & "$vpnClientDir\vpnclient.exe" connect $Name

$stat = .\Get-VPNStatus.ps1

if (!$stat.Connected) {
	write-host $result
	throw("Connect failed.")
}
