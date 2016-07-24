# v1.0 http://huddledmasses.org/configuration-files-for-powershell-part-1/
# v2.0 wrap as Import/Convert
# v2.1 Add a few helper functions so we can have type-safe GUIDs, DateTime, and even PSCustomObject
#      The custom object isn't really necessary, since it's roughly equivalent to a hashtable (script not supported)

function Import-PSData {
   # .Synopsis
   #  Import PowerShell Data Language files (.psd1)
   [CmdletBinding()]param(
      #  A psd1 file to process
      [Parameter(ValueFromPipelineByPropertyName=$True, Position=0, Mandatory=$true)]
      [Alias("PSPath")]
      [String]$Path,

      #  The commands that are allowed in the data language.
      #  Defaults: "ConvertFrom-StringData", "Join-Path"
      [string[]]$AllowedCommands  = ("PSObject", "GUID", "DateTime", "DateTimeOffset", "ConvertFrom-StringData", "Join-Path"),

      #  Additional variables that are allowed in the data language.
      #  These constants are always allowed: "PSScriptRoot", "PSCulture","PSUICulture","True","False","Null"
      [string[]]$AllowedVariables = @(),

      #  The PSScriptRoot value (defaults to the PSParentPath of the input file)
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      [Alias("PSParentPath")]
      $ScriptRoot = $(if($Path){Split-Path $Path})
   )
   process {
      $ErrorActionPreference = "Stop"
      # If we can't read the file, we're done here.
      $PSData = Get-Content $Path -Raw

      $null = $PSBoundParameters.Remove("Path")
      if(!$PSBoundParameters.ContainsKey("ScriptRoot")){
         $PSBoundParameters["ScriptRoot"] = $ScriptRoot
      }

      ConvertFrom-PSData $PSData @PSBoundParameters
   }
}


function ConvertFrom-PSData {
   # .Synopsis
   #  Import PowerShell Data Language files (.psd1)
   [CmdletBinding()]param(
      #  A psd1 file to process
      [Parameter(ValueFromPipeline=$True, Position=0, Mandatory=$true)]
      [String]$InputObject,

      #  The commands that are allowed in the data language.
      #  Defaults: "ConvertFrom-StringData", "Join-Path"
      [string[]]$AllowedCommands  = ("PSObject", "GUID", "DateTime", "DateTimeOffset", "ConvertFrom-StringData", "Join-Path"),

      #  Additional variables that are allowed in the data language.
      #  These constants are always allowed: "PSScriptRoot", "PSCulture","PSUICulture","True","False","Null"
      [string[]]$AllowedVariables = @(),

      #  The PSScriptRoot value (defaults to the PSParentPath of the input file)
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      [Alias("PSParentPath")]
      $ScriptRoot = $Pwd
   )
   begin {
      $AllowedVariables += "PSScriptRoot", "ScriptRoot","PSCulture","PSUICulture","True","False","Null"
      $PSData = ""
   }
   process {
      $PSData += $InputObject
   }
   end {
      $ErrorActionPreference = "Stop"
      $ScriptRoot = Convert-Path $ScriptRoot

      # We can't have a signature block in DataLanguage, but PowerShell will sign psd1 files (WAT?!)
      $PSData = $PSData -replace "# SIG # Begin signature block(?s:.*)"

      # STEP ONE: Parse the file
      $Tokens = $Null; $ParseErrors = $Null
      $AST = [System.Management.Automation.Language.Parser]::ParseInput($PSData, [ref]$Tokens, [ref]$ParseErrors)

      if($ParseErrors -ne $null) {
         $PSCmdlet.ThrowTerminatingError( (New-Object System.Management.Automation.ErrorRecord "Parse error reading $Path", "Parse Error", "InvalidData", $ParseErrors) )
      }

      # There's no way to set PSScriptRoot, so I can't make it return the right value
      if($roots = @($Tokens | Where-Object { ("Variable" -eq $_.Kind) -and ($_.Name -eq "PSScriptRoot") } | ForEach-Object { $_.Extent } )) {
         for($r = $roots.count - 1; $r -ge 0; $r--) {
            # Make $PSScriptRoot with $ScriptRoot instead.
            $PSData = $PSData.Remove($roots[$r].StartOffset+1, 2)
         }
         $AST = [System.Management.Automation.Language.Parser]::ParseInput($PSData, [ref]$Tokens, [ref]$ParseErrors)
      }

      $Script = $AST.GetScriptBlock()
      # STEP TWO: CheckRestrictedLanguage, if it fails, die.
      $Script.CheckRestrictedLanguage( $AllowedCommands, $AllowedVariables, $true )

      # STEP THREE: Invoke, but take credit for the errors
      try { $Script.InvokeReturnAsIs(@()) } catch { $PSCmdlet.ThrowTerminatingError($_) }
   }
}



# These functions are helpers to let us use dissallowed types in data sections
# (see about_data_sections) and .psd1 files (see ConvertFrom-DataString)
function PSObject {
   <#
      .Synopsis
         Creates a new PSCustomObject with the specified properties
      .Description
         This is just a wrapper for the PSObject constructor with -Property $Value
         It exists purely for the sake of psd1 serialization
      .Parameter Value
         The hashtable of properties to add to the created objects
   #>
   param([hashtable]$Value)
   New-Object System.Management.Automation.PSObject -Property $Value
}

function Guid {
   <#
      .Synopsis
         Creates a GUID with the specified value
      .Description
         This is basically just a type cast to GUID.
         It exists purely for the sake of psd1 serialization
      .Parameter Value
         The GUID value.
   #>
   param([string]$Value)
   [Guid]$Value
}

function DateTime {
   <#
      .Synopsis
         Creates a DateTime with the specified value
      .Description
         This is basically just a type cast to DateTime, the string needs to be castable.
         It exists purely for the sake of psd1 serialization
      .Parameter Value
         The DateTime value, preferably from .Format('o'), the .Net round-trip format
   #>
   param([string]$Value)
   [DateTime]$Value
}

function DateTimeOffset {
   <#
      .Synopsis
         Creates a DateTimeOffset with the specified value
      .Description
         This is basically just a type cast to DateTimeOffset, the string needs to be castable.
         It exists purely for the sake of psd1 serialization
      .Parameter Value
         The DateTimeOffset value, preferably from .Format('o'), the .Net round-trip format
   #>
   param([string]$Value)
   [DateTimeOffset]$Value
}

export-modulemember Import-PSData
