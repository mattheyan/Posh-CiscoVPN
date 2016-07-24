[CmdletBinding()]
param(
	# The path to the profile to add.
	[Alias('Profile')]
	[Parameter(Mandatory=$true, HelpMessage="Enter the path to the profile to add.")]
	[string]$Path
)

$installPath = .\Get-CiscoVpnPath.ps1 -ErrorAction Stop

if (-not(Test-Path $Path)) {
	throw("Path '$($Path)' does not exist.")
}

$profileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)

if (.\Get-CiscoVpnProfile.ps1 -Name $profileName -ErrorAction SilentlyContinue) {
	Write-Warning "Profile '$($profileName)' already exists."
} else {
	Write-Host "Importing profile '$($profileName)'..."
	Copy-Item $Path "$($installPath)\Profiles" | Out-Null
}
