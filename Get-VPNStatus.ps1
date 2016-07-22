. .\__init__.ps1


EnsureInstalled

$versionExpr = "^Cisco Systems VPN Client Version ((\d+\.)+\d+)$"
$copyrightExpr = "^Copyright \(C\)"

function ParseKeyValue($text) {
	$idx = $text.IndexOf(":")
	if ($idx -le 0) {
		return $null
	}
	else {
		$left = $text.Substring(0, $idx).Trim()
		$right = $text.Substring($idx + 1).Trim()
		$key = (Get-Culture).TextInfo.ToTitleCase($left.ToLower()).Replace(" ", "")
		return @($key, $right)
	}
}

$stat = new-object System.Object
$line = $null

& "$vpnClientDir\vpnclient.exe" stat | foreach {
	$line = $_
	#write-host $_ -ForegroundColor DarkGray
	if ($_ -match $versionExpr) {
		$stat | Add-Member -type NoteProperty -name "Version" -value ($_ -replace $versionExpr, '$1')
	}
	elseif ($_ -match $copyrightExpr) {
		# Do nothing
	}
	else {
		$keyValue = ParseKeyValue $_
		if ($keyValue) {
			$stat | Add-Member -type NoteProperty -name $keyValue[0] -value $keyValue[1]
		}
	}
}

$stat | Add-Member -type NoteProperty -name "Connected" -value ($line -ne "No connection exists.")
write-output $stat
