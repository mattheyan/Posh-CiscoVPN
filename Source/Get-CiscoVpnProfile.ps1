[CmdletBinding()]
param(
    # The name of the profile to retrieve.
	[Parameter(Mandatory=$true, HelpMessage="Enter the name of the profile to retrieve.")]
	[string]$Name
)

$installPath = .\Get-CiscoVpnPath.ps1 -ErrorAction Stop

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
