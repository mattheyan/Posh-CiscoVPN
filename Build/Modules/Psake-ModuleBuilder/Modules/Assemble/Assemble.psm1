function GetTempDirectory {
    $tempDir = [system.io.path]::GetTempPath()
    $rndName = [system.io.path]::GetRandomFileName()
    $path = Join-Path $tempDir $rndName
    New-Item $path -Type Directory | Out-Null
    foreach ($a in $args) {
        New-Item $path\$a -Type Directory | Out-Null
    }
    return $path
}

function EnsureDirectory ([string]$path, [boolean]$defaultToCurrentLocation) {
    if ($path) {
        $path = $path.Trim()
    }

    if (!$path -and $defaultToCurrentLocation) {
        $path = Get-Location
    }
    elseif (!(Test-Path $path)) {
        Write-Error "ERROR: Path $path does not exist."
        exit 1
    }
    else {
        $path = (Resolve-Path $path).Path
        if (!(Get-Item $path).PSIsContainer) {
            Write-Error "ERROR: Path $path is not a directory."
            exit 1
        }
    }
    
    return $path
}


function Invoke-ScriptBuild {
	[CmdletBinding()]
	param(
	    [Parameter(Mandatory=$true, HelpMessage="Name of the module to build")]
	    [string]$Name,
	
	    [Parameter(Mandatory=$false, HelpMessage="Path to the directory that contains the source files for the module")]
	    [string]$SourcePath,
	
	    [Parameter(Mandatory=$false, HelpMessage="Path to the directory where the completed module will be copied")]
	    [string]$TargetPath,
	
	    [Parameter(Mandatory=$false, HelpMessage="The names of dependent modules to validate")]
	    [array]$DependenciesToValidate=@(),
	
	    [Parameter(Mandatory=$false, HelpMessage="Forcibly copy over the module file if it already exists")]
	    [switch]$Force,
	
	    [Parameter(Mandatory=$false, HelpMessage="PowerShell scripts (.ps1) to exclude from source files that are included")]
	    [string[]]$Exclude,
	
	    [Parameter(Mandatory=$false, HelpMessage="Flags used by preprocessor.")]
	    [string[]]$Flags,
	
		[Parameter(Mandatory=$false, HelpMessage="Don't write status messages.")]
		[switch]$Silent
	)
	
	
	# Ensure that the source and target paths valid directories if specified
	$SourcePath = EnsureDirectory $SourcePath $true
	$TargetPath = EnsureDirectory $TargetPath $true
	
	# Create a temporary directory to build in
	$buildDir = GetTempDirectory
	
	if ($Silent.IsPresent) {
		Write-Verbose "Starting script build for module '$($Name)'."
	} else {
		Write-Host "Starting script build for module '$($Name)'."
	}
	
	Write-Verbose "NOTE: Building in temporary directory '$($buildDir)'..."
	
	$moduleFile = "$buildDir\$($Name).psm1"
	
	if ($Silent.IsPresent) {
		Write-Verbose "Creating empty module file..."
	} else {
		Write-Host "Creating empty module file..."
	}
	
	New-Item $moduleFile -Type File | Out-Null
	
	# Ensure that required modules are available and loaded
	$DependenciesToValidate | foreach {
	    Write-Verbose "Adding dependency to" + $_
	    Add-Content -Path $moduleFile -Value ("if (!(Get-Module " + $_ + ")) {")
	    Add-Content -Path $moduleFile -Value ("`tImport-Module " + $_ + " -ErrorAction Stop")
	    Add-Content -Path $moduleFile -Value "}"
	    Add-Content -Path $moduleFile -Value ""
	}
	
	$symbols = @()
	$sources = @()
	
	if ($Silent.IsPresent) {
		Write-Verbose "Searching for source files to include..."
	} else {
		Write-Host "Searching for source files to include..."
	}
	
	Get-ChildItem -Path $SourcePath -Exclude $Exclude -Filter "*.ps1" -Recurse | %{
	    if ($_.Name -eq "__init__.ps1") {
	        Write-Verbose "Found __init__ (initialize) file."
	        $sources += $_.FullName
	    }
	    elseif ($_.Name -eq "__final__.ps1") {
	        Write-Verbose "Found __final__ (finalize) file."
	        $sources += $_.FullName
	    }
	    elseif ($_.Name -match "([A-Z][a-z]+`-[A-Z][A-Za-z]+)`.ps1") {
	        Write-Verbose "Found source file $($_)."
	        $symbols += $_.Name -replace ".ps1", ""
	        $sources += $_.FullName
	    }
	    else {
	        throw "Invalid file name '$($_.Name)'."
	    }
	}
	
	Write-Verbose "Symbols: $symbols"
	
	$initFileExpr = "^\s*\. \.\\__init__\.ps1$"
	
	$ifExpr = "^\s*#if"
	$ifDefExpr = "^\s*#ifdef\s+(.+)\s*$"
	
	$initFile = (resolve-path $SourcePath).Path + "\__init__.ps1"
	$finalFile = (resolve-path $SourcePath).Path + "\__final__.ps1"
	
	if ($Silent.IsPresent) {
		Write-Verbose "Including source files..."
	} else {
		Write-Host "Including source files..."
	}
	
	if ($sources -contains $initFile) {
	    Write-Verbose "Including file __init__.ps1"
	    $ignore = $false
	    (Get-Content $initFile | % {
	        if ($_ -match $ifExpr) {
	            if ($_ -match $ifdefExpr) {
	                $flag = $_ -replace $ifdefExpr, '$1'
	                Write-Verbose "Checking for flag $($flag)..."
	                if ($Flags -contains $flag) {
	                    Write-Verbose "Found flag $flag."
	                }
	                else {
	                    Write-Verbose "Did not find flag $flag. Ignoring content..."
	                    $ignore = $true
	                }
	            }
	            else {
	                throw "Invalid #if block: $_"
	            }
	        }
	        elseif ($_ -match "^\s*#endif\s*$") {
	            $ignore = $false
	        }
	        elseif ($ignore) {
	            Write-Verbose "Ignored: $_"
	        }
	        else {
	            Write-Output $_
	        }
	    }) | Add-Content -Path $moduleFile
	    Add-Content -Path $moduleFile -Value "`r`n"
	}
	
	$sources | sort Name | foreach {
	    if ($_ -ne $initFile -and $_ -ne $finalFile) {
	        $n = ((Split-Path -Path $_ -Leaf) -replace ".ps1", "")
	        Write-Verbose "Including file $($n).ps1"
	        if ($n -ne "__init__") {
	            Add-Content -Path $moduleFile -Value ("function " + $n + " {")
	        }
	        $ignore = $false
	        ((Get-Content $_) | % {
	            if ($_ -match $ifExpr) {
	                if ($_ -match $ifdefExpr) {
	                    $flag = $_ -replace $ifdefExpr, '$1'
	                    Write-Verbose "Checking for flag $($flag)..."
	                    if ($Flags -contains $flag) {
	                        Write-Verbose "Found flag $flag."
	                    }
	                    else {
	                        Write-Verbose "Did not find flag $flag. Ignoring content..."
	                        $ignore = $true
	                    }
	                }
	                else {
	                    throw "Invalid #if block: $_"
	                }
	            }
	            elseif ($_ -match "^\s*#endif\s*$") {
	                $ignore = $false
	            }
	            elseif ($ignore) {
	                Write-Verbose "Ignored: $_"
	            }
	            else {
	                $newLine = "`t" + $_
	                $foundFileRefs = $false
	                if ($newLine -match $initFileExpr) {
	                    $newLine = ""
	                    $foundFileRefs = $true
	                    Write-Verbose "Removed dot-source of '__init__.ps1'."
	                }
	                else {
	                    $symbols | foreach {
	                        $symbolExpr = "\.\\" + $_ + "\.ps1"
	                        if ($newLine -match $symbolExpr) {
	                            $foundFileRefs = $true
	                            Write-Verbose "Found file reference to symbol '$($_)'."
	                        }
	                        $newLine = $newLine -replace $symbolExpr, $_
	                    }
	                    if ($foundFileRefs -eq $true) {
	                        Write-Verbose "Result: $newLine"
	                    }
	                }
	                if ($newLine) {
	                    Write-Output $newLine
	                }
	            }
	        }) | Add-Content -Path $moduleFile
	        if ($n -ne "__init__") {
	            Add-Content -Path $moduleFile -Value "}`r`n"
	        }
	    }
	}
	
	if ($Silent.IsPresent) {
		Write-Verbose "Registering export for symbols..."
	} else {
		Write-Host "Registering export for symbols..."
	}
	
	$symbols | foreach {
	    Add-Content -Path $moduleFile -Value ("Export-ModuleMember -Function " + $_)
	}
	
	if ($sources -contains $finalFile) {
	    Write-Verbose "Including file __final__.ps1"
	    $ignore = $false
	    (Get-Content $finalFile | % {
	        if ($_ -match $ifExpr) {
	            if ($_ -match $ifdefExpr) {
	                $flag = $_ -replace $ifdefExpr, '$1'
	                Write-Verbose "Checking for flag $($flag)..."
	                if ($Flags -contains $flag) {
	                    Write-Verbose "Found flag $flag."
	                }
	                else {
	                    Write-Verbose "Did not find flag $flag. Ignoring content..."
	                    $ignore = $true
	                }
	            }
	            else {
	                throw "Invalid #if block: $_"
	            }
	        }
	        elseif ($_ -match "^\s*#endif\s*$") {
	            $ignore = $false
	        }
	        elseif ($ignore) {
	            Write-Verbose "Ignored: $_"
	        }
	        else {
	            Write-Output $_
	        }
	    }) | Add-Content -Path $moduleFile
	    Add-Content -Path $moduleFile -Value "`r`n"
	}
	
	# Copy completed module to the current directory
	if ((test-path -Path .\$($Name).psm1) -and !$Force.IsPresent) {
	    throw "File '$($Name).psm1' already exists!"
	}
	
	if ($Silent.IsPresent) {
		Write-Verbose "Moving completed module to '$($TargetPath)'..."
	} else {
		Write-Host "Moving completed module to '$($TargetPath)'..."
	}
	
	Copy-Item $moduleFile $TargetPath -Force | Out-Null
}

Export-ModuleMember -Function Invoke-ScriptBuild
