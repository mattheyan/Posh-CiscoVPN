. .\__init__.ps1

EnsureInstalled
$stat = .\Get-VPNStatus.ps1

if ($stat.Connected) {
	$result = & "$vpnClientDir\vpnclient.exe" disconnect
	$stat = .\Get-VPNStatus.ps1
	if ($stat.Connected) {
		write-host $result
		throw("Disconnect failed.")
	}
}
else {
	write-host "Not currently connected..." -ForegroundColor Yellow
}
