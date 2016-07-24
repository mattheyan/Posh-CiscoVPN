function Get-CiscoVpnPath {
	[CmdletBinding()]
	param(
	)
	
	$path = "C:\Program Files (x86)\Cisco Systems\VPN Client"
	
	if (-not(Test-Path $path)) {
	    Write-Error "The Cisco VPN client is not installed."
	    return
	}
	    
	$result = New-Object 'PSCustomObject'
	$result | Add-Member -NotePropertyName 'Path' -NotePropertyValue $path
	$result | Add-Member -Type ScriptMethod -Name 'ToString' -Value { $this.Path } -Force
	return $result
}

function Get-CiscoVpnProfile {
	[CmdletBinding()]
	param(
	    # The name of the profile to retrieve.
		[Parameter(Mandatory=$true, HelpMessage="Enter the name of the profile to retrieve.")]
		[string]$Name
	)
	
	$installPath = Get-CiscoVpnPath -ErrorAction Stop
	
	$profilePath = "$($installPath)\Profiles\$($Name).pcf"
	
	if (Test-Path $profilePath) {
	    Write-Verbose "Profile '$($Name)' found at '$($profilePath)'."
	
	    $result = New-Object 'PSCustomObject'
	
	    $result | Add-Member -NotePropertyName 'Name' -NotePropertyValue $Name
	    $result | Add-Member -NotePropertyName 'Path' -NotePropertyValue $profilePath
	
	    $section = $null
	
	    Get-Content $profilePath | foreach {
	        Write-Verbose $_
	        if ($_ -match '^\[([A-Za-z][A-Za-z0-9]+)\]$') {
	            $sectionName = $_ -replace '^\[([A-Za-z][A-Za-z0-9]+)\]$', '$1'
	            $section = New-Object 'PSCustomObject'
	            $result | Add-Member -NotePropertyName (Get-Culture).TextInfo.ToTitleCase($sectionName) -NotePropertyValue $section
	        } elseif ($section) {
	    		$idx = $_.IndexOf('=')
	    		if ($idx -gt 0) {
	    			$left = $_.Substring(0, $idx).Trim()
	    			$right = $_.Substring($idx + 1).Trim()
	    			$section | Add-Member -type NoteProperty -name $left -value $right
	    		}
	        }
	    }
	
	    return $result
	}
	else {
	    Write-Error "Profile '$($Name)' was not found."
	}
}

function Get-CiscoVpnStatus {
	[CmdletBinding()]
	param(
	)
	
	$installPath = Get-CiscoVpnPath -ErrorAction Stop
	
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
}

function Add-CiscoVpnProfile {
	[CmdletBinding()]
	param(
		# The path to the profile to add.
		[Alias('Profile')]
		[Parameter(Mandatory=$true, HelpMessage="Enter the path to the profile to add.")]
		[string]$Path
	)
	
	$installPath = Get-CiscoVpnPath -ErrorAction Stop
	
	if (-not(Test-Path $Path)) {
		throw("Path '$($Path)' does not exist.")
	}
	
	$profileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
	
	if (Get-CiscoVpnProfile -Name $profileName -ErrorAction SilentlyContinue) {
		Write-Warning "Profile '$($profileName)' already exists."
	} else {
		Write-Host "Importing profile '$($profileName)'..."
		Copy-Item $Path "$($installPath)\Profiles" | Out-Null
	}
}

function Connect-CiscoVpn {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="The name of the profile to connect.")]
		[string]$Name
	)
	
	$installPath = Get-CiscoVpnPath -ErrorAction Stop
	
	Get-CiscoVpnProfile -Name $Name -ErrorAction Stop | Out-Null
	
	$status = Get-CiscoVpnStatus
	
	if ($status.Connected) {
		if ($status.ConnectionEntry -eq $Name) {
			Write-Host "Already connected to '$($Name)'."
			return
		}
	
		Write-Host "Disconnecting from '$($status.ConnectionEntry)'..."
		Disconnect-CiscoVpn
	}
	
	$outputLines = @()
	& "$($installPath)\vpnclient.exe" connect $Name | foreach {
		$outputLines += $_
	}
	
	$status = Get-CiscoVpnStatus
	
	if (-not($status.Connected)) {
		$outputLines | foreach {
			Write-Host $_
		}
		Write-Error "Connect failed."
	}
}

function Disconnect-CiscoVpn {
	[CmdletBinding()]
	param(
	)
	
	$installPath = Get-CiscoVpnPath -ErrorAction Stop
	
	$status = Get-CiscoVpnStatus
	
	if ($status.Connected) {
		$outputLines = @()
		& "$($installPath)\vpnclient.exe" disconnect | foreach { $outputLines += $_ }
		$status = Get-CiscoVpnStatus
		if ($status.Connected) {
			$outputLines | foreach { Write-Host $_ }
			Write-Error "Unable to disconnect from '$($status.ConnectionEntry)'."
		}
	} else {
		Write-Verbose "Not currently connected."
	}
}

Export-ModuleMember -Function Add-CiscoVpnProfile
Export-ModuleMember -Function Connect-CiscoVpn
Export-ModuleMember -Function Disconnect-CiscoVpn
Export-ModuleMember -Function Get-CiscoVpnPath
Export-ModuleMember -Function Get-CiscoVpnProfile
Export-ModuleMember -Function Get-CiscoVpnStatus
