$vpnClientDir = "C:\Program Files (x86)\Cisco Systems\VPN Client"

$vpnProfilesDir = "$vpnClientDir\Profiles"

function Installed?
{
	param(
		[switch]$Assert
	)
	
	#write-host "Checking for Cisco VPN Client..." -ForegroundColor DarkGray
	if (test-path $vpnClientDir) {
		#write-host "VPN Client found." -ForegroundColor DarkGray
		return $true
	}
	else {
		if ($Assert.IsPresent) {
			throw("Cisco VPN Client is NOT found.")
		}
		else {
			#write-host "Cisco VPN Client is NOT found." -ForegroundColor DarkGray
			return $false
		}
	}
}

function EnsureInstalled
{
	$result = Installed? -Assert
}

function Profile?
{
	param(
		[Parameter(Mandatory=$true, HelpMessage="The name of the profile.")]
		[string]$Name,
		[switch]$Assert
	)
	
	if ($Name.Trim().Length -eq 0) {
		throw("A profile name is required.")
	}
	
	if (test-path "$vpnProfilesDir\$($Name).pcf") {
		#write-host "$Name profile found." -ForegroundColor DarkGray
		return $true
	}
	else {
		if ($Assert.IsPresent) {
			throw("$Name profile NOT found.")
		}
		else {
			#write-host "$Name profile NOT found." -ForegroundColor DarkGray
			return $false
		}
	}
}

function EnsureProfile
{
	param(
		[Parameter(Mandatory=$true, HelpMessage="The name of the profile.")]
		[string]$Name
	)

	$result = Profile? -Name $Name -Assert
}
