$psakeModuleBuilderDir = Split-Path $MyInvocation.MyCommand.Path -Parent

properties {
    if (-not($moduleSpecFile)) {
        if (Test-Path "$root\module.psd1") {
            $moduleSpecFile = "$root\module.psd1"
        } else {
            throw "Couldn't auto-discover module spec file 'module.psd1'."
        }
    }

    $moduleSpec = Import-PSData $moduleSpecFile

    if (-not($moduleSpec.Guid)) {
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $moduleGuidData = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($moduleSpec.Name.ToLower()));
        $moduleGuid = New-Object 'System.Guid' -ArgumentList (,$moduleGuidData)
        $moduleSpec.Guid = "$($moduleGuid.ToString().ToLowerInvariant())"
    }

    $packageId = 'ChocolateyHelpers.extension'
    $packageDestination = "$root\Output"
    $packageDescription = $moduleSpec.Description
    $packageAuthors = $moduleSpec.Author
    $packageOwners = $moduleSpec.Author
}

task ModuleBuilder:Build {
    $moduleName = $moduleSpec.Name

    $moduleSource = $moduleSpec.Source
    if (-not($moduleSource)) {
        if (Test-Path "$root\Source") {
            $moduleSource = "$root\Source"
        } else {
            throw "Couldn't auto-discover module source folder 'Source'."
        }
    }

    if (-not($moduleDestination)) {
        $moduleDestination = $moduleSpec.Destination
        if (-not($moduleDestination)) {
            throw "Module destination path not configured."
        }
    }

    Write-Message "Building module '$($moduleName)'..."
    Invoke-ScriptBuild -Name $moduleName -SourcePath $moduleSource -TargetPath $moduleDestination -Force

    Write-Message "Generating module manifest '$($moduleName).psd1' from template..."
	$manifestFile = Join-Path $moduleDestination "$($moduleName).psd1"
	$manifestTemplateFile = Join-Path $psakeModuleBuilderDir "Templates\ModuleManifest.psd1.tmpl"
	$manifestContent = Expand-Template -File $manifestTemplateFile -Binding $moduleSpec
	($manifestContent.Trim() -split "`n") -join "`r`n" | Out-File "$($manifestFile)" -Encoding UTF8
}
