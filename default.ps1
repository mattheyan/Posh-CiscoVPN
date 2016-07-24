$root = Split-Path $MyInvocation.MyCommand.Path -Parent

Write-Verbose "Loading 'default.ps1'..."

Write-Verbose "root=$root"

include '.\Modules\Psake-Utils\psake-tasks.ps1'

properties {
    Write-Verbose "Applying properties from 'default.ps1'..."

    $projectName = 'CiscoVPN'
}

if (Test-Path ".\psake-local.ps1") {
    Write-Message "Importing local file '.\psake-local.ps1'..."
    include '.\psake-local.ps1'
} else {
    Write-Message "Local 'psake-tasks' file not found at '.\psake-local.ps1'..."
}

include '.\Build\psake-tasks.ps1'

task Help -depends Choco:Help,Utils:Help
