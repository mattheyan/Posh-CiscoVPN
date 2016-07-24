[CmdletBinding()]
param(
)

$installPath = .\Get-CiscoVpnPath.ps1 -ErrorAction Stop

$versionExpr = '^Cisco Systems VPN Client Version ((\d+\.)+\d+)$'
$copyrightExpr = '^Copyright \(C\)'

$result = New-Object 'PSCustomObject'

$connected = $null

& "$($installPath)\vpnclient.exe" stat | foreach {
	Write-Verbose $_
	if ($_ -match $versionExpr) {
		$result | Add-Member -type NoteProperty -name 'Version' -value ($_ -replace $versionExpr, '$1')
	} elseif ($_ -match $copyrightExpr) {
		# Do nothing
	} elseif ($_ -eq 'No connection exists.') {
		$connected = $false
	} else {
		$idx = $_.IndexOf(':')
		if ($idx -gt 0) {
			$left = $_.Substring(0, $idx).Trim()
			$right = $_.Substring($idx + 1).Trim()
			$key = (Get-Culture).TextInfo.ToTitleCase($left.ToLower().Replace('(s)', '')).Replace(' ', '')
			if (-not($connected) -and $key -eq 'ConnectionEntry') {
				$connected = $true
			}
			$result | Add-Member -type NoteProperty -name $key -value $right
		}
	}
}

$result | Add-Member -type NoteProperty -name 'Connected' -value $connected

return $result
