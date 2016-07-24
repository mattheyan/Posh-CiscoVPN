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
