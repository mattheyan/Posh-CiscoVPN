powershell -Command "$modulePath=((Split-Path -Path $profile -Parent) + '\Modules'); $package = $env:temp + '\' + [string][system.guid]::NewGuid(); Import-Module powpack; New-Package -SourcePath . -TargetPath $package -Exclude .\bin -ModuleName poshvpn; new-item $modulePath\poshvpn -type Directory -Force; copy-item ((get-childitem $package) | foreach-object { $_.FullName }) $modulePath\poshvpn;"
pause