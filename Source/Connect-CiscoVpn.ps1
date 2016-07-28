[CmdletBinding(DefaultParameterSetName='Prompt')]
param(
	# The name of the profile to connect.
	[Parameter(Mandatory=$true, Position=0, HelpMessage="Enter the profile name")]
	[string]$Name,

	[Parameter(Mandatory=$true, Position=1, ParameterSetName='UserPwd', HelpMessage="Enter the username")]
	[string]$User,

	[Parameter(Mandatory=$true, Position=2, ParameterSetName='UserPwd', HelpMessage="Enter the password")]
	[SecureString]$Password
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

if ($PSCmdlet.ParameterSetName -eq 'Prompt') {
	& "$($installPath)\vpnclient.exe" connect """$Name""" | foreach {
		$outputLines += $_
	}
} elseif ($PSCmdlet.ParameterSetName -eq 'UserPwd') {
	$passwordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $passwordRaw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBSTR)
	& "$($installPath)\vpnclient.exe" connect """$Name""" user """$User""" pwd """$passwordRaw""" | foreach {
		$outputLines += $_
	}
}

$status = .\Get-CiscoVpnStatus.ps1

if (-not($status.Connected)) {
	$outputLines | foreach {
		Write-Host $_
	}
	Write-Error "Connect failed."
}
