$psakeUtilsDir = Split-Path $MyInvocation.MyCommand.Path -Parent

if (-not($root)) {
	$root = Split-Path (Split-Path $psakeUtilsDir -Parent) -Parent
}

function Write-Message {
	[CmdletBinding()]
	param(
		[string]$Message,

		[switch]$NoTimestamp,

		# http://stackoverflow.com/a/2795683
		[Parameter(ValueFromRemainingArguments=$true)]
		$Params
	)

	$fmtArgs = @()

	if ($Params) {
		$Params | ForEach-Object {
			Write-Verbose "Processing parameter $($_)..."
			if ($_.StartsWith($root)) {
				Write-Verbose "Parameter is a relative path."
				$fmtArgs += "'[[Cyan:.\$($_.Substring($root.Length + 1))]]'"
			} else {
				$fmtArgs += $_
			}
		}

		$text = [string]::Format($Message, $fmtArgs)
	} else {
		$text = $Message
	}

	Write-Verbose "text=$text"

	#"(?<=[^\-_ \.A-Za-z0-9])$($rootLiteral)\\([\-_ \.A-Za-z0-9]+)"
	$rootedPathExpr = "(?<=['""])$([System.Text.RegularExpressions.Regex]::Escape($root))(\\(?:(\.\.)|(?:[\-_ \.A-Za-z0-9]+[A-Za-z0-9]+)))*(?=['""])"

	while ($text -match $rootedPathExpr) {
		$match = [System.Text.RegularExpressions.Regex]::Match($text, $rootedPathExpr)

		$preceding = $text[$match.Index - 1]
		$following = $text[$match.Index + $match.Length]

		$prefix = if ($match.Index -gt 0) { $text.Substring(0, $match.Index) } else { $null }
		$matchedPath = $match.Captures[0].Value
		$suffix = if ($match.Index + $match.Length -lt $text.Length - 1) { $text.Substring($match.Index + $match.Length) } else { $null }

		$text = $prefix

		if ($preceding -ne $following) {
			$text += "[[White:$($matchedPath)]]"
		} else {
			$relativePath = if ($matchedPath -eq $root) { '.' } else { '.\' + $matchedPath.Substring($root.Length + 1) }
			$text += "[[Cyan:$($relativePath)]]"
		}

		$text += $suffix
	}

	$tokens = [System.Text.RegularExpressions.Regex]::Split($text, "(?=\[\[)|(?<=\[\[)|(?=\]\])|(?<=\]\])")

	if (-not($NoTimestamp.IsPresent)) {
		$ts = Get-Date
		Write-Host "[" -NoNewLine
		Write-Host "$($ts.ToString('HH:mm:ss'))" -ForegroundColor DarkGray -NoNewLine
		Write-Host "] " -NoNewLine
	}

	for ($i = 0; $i -lt $tokens.Length; $i += 1) {
		$t = $tokens[$i]
		if ($t -ne '[[' -and $t -ne ']]') {
			if ($i -gt 0 -and $tokens[$i - 1] -eq '[[') {
				$delimiterIndex = $t.IndexOf(':')
				$color = $t.Substring(0, $delimiterIndex)
				$str = $t.Substring($delimiterIndex + 1)
				Write-Host $str -ForegroundColor $color -NoNewline
			} else {
				Write-Host $t -NoNewline
			}
		}
	}

	Write-Host ""
}
