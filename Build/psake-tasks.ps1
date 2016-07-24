Write-Verbose "Loading 'Build\psake-tasks.ps1'..."

properties {
    Write-Verbose "Applying properties from 'Build\psake-tasks.ps1'..."

    $moduleSpecFile = "$root\module.psd1"
    $moduleDestination = "$root\CiscoVPN"

    $projectLicense = 'MIT'
    $projectUrl = 'https://github.com/mattheyan/Posh-CiscoVPN'
}

include '.\Build\Modules\Psake-ModuleBuilder\psake-tasks.ps1'

task Build -depends ModuleBuilder:Build
