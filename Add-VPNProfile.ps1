param(
	[Parameter(Mandatory=$true, HelpMessage="The path to the profile to add.")]
	[string]$Profile
)

if (!(test-path $Profile)) {
	throw("Path '$Profile' does not exist.")
}

. .\__init__.ps1

EnsureInstalled

$name = (split-path $Profile -Leaf) -replace "^(.+)\.pcf$", '$1'

if (Profile? -Name $name) {
	write-host "Profile already exists." -ForegroundColor Yellow
}
else {
	write-host "Importing $name profile..." -ForegroundColor DarkGray
	copy-item $FilePath $vpnProfilesDir
}
