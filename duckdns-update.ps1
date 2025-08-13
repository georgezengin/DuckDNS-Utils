#Requires -Version 2

<#
.SYNOPSIS
	Updates the IP address of your Duck DNS domain(s).
.DESCRIPTION
	Updates the IP address of your Duck DNS domain(s). Intended to be run as a
	scheduled task.
.PARAMETER Domains
	A comma-separated list of your Duck DNS domains to update.
.PARAMETER Token
	Your Duck DNS token.
.PARAMETER IP
	The IP address to use. If you leave it blank, Duck DNS will detect your
	gateway IP.
.PARAMETER Help
	Show usage information.
.PARAMETER DryRun
	Show what would be done without making actual changes.
.PARAMETER DisableEventLog
	Disable Windows Event Log logging.
.PARAMETER DebugConsole
	Enable console output of messages.
.INPUTS
	None. You cannot pipe objects to this script.
.OUTPUTS
	None. This script does not generate any output.
.EXAMPLE
	.\Update-DuckDNS.ps1 -Domains "foo,bar" -Token my-duck-dns-token
.EXAMPLE
	.\Update-DuckDNS.ps1 -Help
.EXAMPLE
	.\Update-DuckDNS.ps1 -Domains "foo,bar" -Token my-duck-dns-token -DryRun
.EXAMPLE
	.\Update-DuckDNS.ps1 -Domains "foo,bar" -Token my-duck-dns-token -DebugConsole
.EXAMPLE
	.\Update-DuckDNS.ps1 -Domains "foo,bar" -Token my-duck-dns-token -DisableEventLog
.LINK
	https://github.com/ataylor32/duckdns-powershell
#>

Param (
	# The Duck DNS domains to update. This is a comma-separated list of your
	# Duck DNS domains. You can specify multiple domains by separating them with a comma.
	[Parameter(#Mandatory=$True, 
	HelpMessage="Specify a comma separated list of domains to update.")]
	#[ValidateNotNullOrEmpty()]
	[String]$Domains, # "foo,bar" or "mydomain",

	# The Duck DNS token is required to authenticate the update request.
	# You can find it on your Duck DNS account page.
	[Parameter(#Mandatory=$True, 
	HelpMessage="Specify the Duck DNS token to use for the update.")]
	#[ValidateNotNullOrEmpty()]
	[String]$Token,

	# The IP address to use for the update. If not specified, Duck DNS will
	# automatically detect your gateway IP address.
	[Parameter(HelpMessage="Specify the IP address to use for the update. If not specified, Duck DNS will auto-detect your gateway IP.")]
	[String]$IP,

	# Show usage information
	[Parameter(HelpMessage="Show usage information.")]
	[Switch]$Help,

	# Show what would be done without making actual changes
	[Parameter(HelpMessage="Show what would be done without making actual changes.")]
	[Switch]$DryRun,

	# Disable Windows Event Log logging
	[Parameter(HelpMessage="Disable Windows Event Log logging.")]
	[Switch]$DisableEventLog,

	# Enable console output of messages
	[Parameter(HelpMessage="Enable output of activity messages to the console.")]
	[Switch]$DebugConsole
)

# ===== GLOBAL: Accumulate event log messages =====
$global:EventLogMessages = @()

# Function to write to Windows Event Log
Function Write-EventLogEntry {
	Param(
		[String]$logSource 	= "Duck DNS IP Update",
		[String]$logName   	= "Application",
		[String]$EntryType 	= "Information",
		[Int]$EventId 		= 1000
	)
	
    if ($DisableEventLog -or $DryRun -or $global:EventLogMessages.Count -eq 0) {
        return
    }

    # Check if the event log source exists, create it if not
    if (-not [System.Diagnostics.EventLog]::SourceExists($logSource)) {
        try {
            [System.Diagnostics.EventLog]::CreateEventSource($logSource, $logName)
            Start-Sleep -Seconds 1
        } catch {
            Write-Warning "Failed to create event source: $_"
            return
        }
    }

    $combinedMessage = $global:EventLogMessages -join "`r`n"

    try {
        # Check if Write-EventLog cmdlet is available (Windows PowerShell 5.1)
        if (Get-Command Write-EventLog -ErrorAction SilentlyContinue) {
            #Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId 1000 -Message $combinedMessage
			Write-EventLog -LogName $logName -Source $logSource -EntryType $EntryType -EventId $EventId -Message $combinedMessage
        } else {
            # Use .NET method for PowerShell Core compatibility
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $logSource
            # $eventLog.WriteEntry($combinedMessage, [System.Diagnostics.EventLogEntryType]::Information, 1000)
			$EventLog.WriteEntry($combinedMessage, [System.Diagnostics.EventLogEntryType]::$EntryType, $EventId)
        }
    } catch {
        Write-Warning "Failed to write event log: $_"
    }
    $global:EventLogMessages = @() # Clear messages after writing
}

# Function to write log messages
Function Write-Log {
	Param(
		[String]$Message,
	    [System.ConsoleColor]$Color = $Host.UI.RawUI.ForegroundColor
    )

    # Get current background color
    $bgColor = $Host.UI.RawUI.BackgroundColor

    # If foreground color is same as background, choose a fallback
    if ($Color -eq $bgColor) {
        $Color = if ($bgColor -eq "Black") { "White" } else { "Black" }
    }
	
	$prefix = if ($DryRun) { '[DRY RUN] ' } else { "" }
    $fullMessage = "$prefix$Message"

    if ($DebugConsole) {
        if ([Console]::IsOutputRedirected) {
            # Redirected output → no colors
            [Console]::WriteLine($fullMessage)
        }
        else {
            # Interactive console → colors allowed
            Write-Host $fullMessage -ForegroundColor $Color
        }
    }

    if (-not $DisableEventLog -and -not $DryRun) {
        # Collect messages instead of writing immediately
        $global:EventLogMessages += $fullMessage
    }
}

# Show usage if Help parameter is specified
If ($Help) {
	Write-Host "Duck DNS Update Script" -ForegroundColor Green
	Write-Host "Updates the IP address of your Duck DNS domain(s)." -ForegroundColor White
	Write-Host ""
	Write-Host "USAGE:" -ForegroundColor Yellow
	Write-Host "  .\Update-DuckDNS.ps1 -Domains <domains> -Token <token> [parameters]" -ForegroundColor White
	Write-Host ""
	Write-Host "PARAMETERS:" -ForegroundColor Yellow
	Write-Host "  -Domains <string>       Comma-separated list of Duck DNS domains" -ForegroundColor White
	Write-Host "  -Token <string>         Your Duck DNS token" -ForegroundColor White
	Write-Host "  -IP <string>            IP address (optional - auto-detected if not specified)" -ForegroundColor White
	Write-Host "  -DryRun                 Show what would be done without making changes" -ForegroundColor White
	Write-Host "  -DisableEventLog        Disable Windows Event Log logging" -ForegroundColor White
	Write-Host "  -DebugConsole           Enable console output of messages" -ForegroundColor White
	Write-Host "  -Help                   Show this help message" -ForegroundColor White
	Write-Host ""
	Write-Host "EXAMPLES:" -ForegroundColor Yellow
	Write-Host "  .\Update-DuckDNS.ps1 -Domains 'foo,bar' -Token 'my-token'" -ForegroundColor White
	Write-Host "  .\Update-DuckDNS.ps1 -Domains 'mydomain' -Token 'my-token' -IP '192.168.1.100'" -ForegroundColor White
	Write-Host "  .\Update-DuckDNS.ps1 -Domains 'test' -Token 'my-token' -DryRun" -ForegroundColor White
	Write-Host "  .\Update-DuckDNS.ps1 -Domains 'test' -Token 'my-token' -DebugConsole" -ForegroundColor White
	Write-Host "  .\Update-DuckDNS.ps1 -Domains 'test' -Token 'my-token' -DisableEventLog" -ForegroundColor White
	Write-Host ""
	Exit 0
}

if (-not $Domains) {
	Write-Log "Error: The -Domains parameter is required." -Color "Red"
	Write-EventLogEntry -EntryType "Error" -EventId 1000
	Exit 1
}

if (-not $Token) {
	Write-Log "Error: The -Token parameter is required." -Color "Red"
	Write-EventLogEntry -EntryType "Error" -EventId 1000
	Exit 1
}

# Auto-detect IP if not provided
if (-not $IP) {
	try {
		$IP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=text" -UseBasicParsing)
		Write-Log "Auto-detected external IP: $IP" -Color "Cyan"
	} catch {
		Write-Log "Failed to auto-detect external IP." -Color "Red"
		$IP = ""
	}
}

# $domainsEscaped = [Uri]::EscapeDataString($Domains)
# $ipEscaped      = [Uri]::EscapeDataString($IP)
# $URL = "https://www.duckdns.org/update?domains=$domainsEscaped&token=$Token&ip=$ipEscaped"
# $URL = "https://www.duckdns.org/update?domains={0}&token={1}&ip={2}" -F $domainsEscaped, $Token, $ipEscaped

$URL = "https://www.duckdns.org/update?domains={0}&token={1}&ip={2}" -F $Domains, $Token, $IP

Write-Debug "`$URL set to $URL"

If ($DryRun) {
	Write-Host "[DRY RUN] Would send update request to Duck DNS..." -ForegroundColor Yellow
	Write-Host "[DRY RUN] 	Domains: $Domains" -ForegroundColor White
	Write-Host "[DRY RUN] 	Token: $Token" -ForegroundColor White
	Write-Host "[DRY RUN] 	IP: $(if ($IP) { $IP } else { 'Auto-detect' })" -ForegroundColor White
	Write-Host "[DRY RUN] URL: $URL" -ForegroundColor Green
	Exit 0
}

Write-Log "Sending update request to Duck DNS..." -Color "White"

If ($PSVersionTable.PSVersion.Major -Gt 2) {
	$Result = Invoke-WebRequest $URL

	If ($null -ne $Result) {
		$ResponseString = $Result.ToString()
	}
}
Else {
	if (-not $DryRun) {
		$Request = [System.Net.WebRequest]::Create($URL)
		$Response = $Request.GetResponse()

		If ($null -ne $Response) {
			$StreamReader = New-Object System.IO.StreamReader $Response.GetResponseStream()
			$ResponseString = $StreamReader.ReadToEnd()
		}
	} else {
		$ResponseString = "OK"
	}
}
Write-Log "Request sent to Duck DNS. URL: $URL" -Color "Cyan"
Write-Log "Response from Duck DNS: $ResponseString" -Color $(if ($ResponseString -Eq "OK") { "Green" } else { "Red" })

If ($ResponseString -Eq "OK") {
	$LogMessage = "Duck DNS update successful. Domains: $Domains, IP: $(if ($IP) { $IP } else { 'Auto-detected' })"
	Write-Log $LogMessage -Color "Green"
	Write-EventLogEntry -EntryType "Information"
}
ElseIf ($ResponseString -Eq "KO") {
	$LogMessage = "Duck DNS update failed. Domains: $Domains, IP: $(if ($IP) { $IP } else { 'Auto-detected' })"
	Write-Log $LogMessage -Color "Red"
	Write-EventLogEntry -EntryType "Error" -EventId 1001
} Else {
	$LogMessage = "Duck DNS update returned unexpected response: $ResponseString. Domains: $Domains, IP: $(if ($IP) { $IP } else { 'Auto-detected' })"
	Write-Log $LogMessage -Color "Yellow"
	# Log as warning since it might indicate a problem but not necessarily an error
	Write-EventLogEntry -EntryType "Warning" -EventId 1002
}
