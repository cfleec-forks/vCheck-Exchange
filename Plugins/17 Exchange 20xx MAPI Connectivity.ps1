# Based on code in http://www.powershellneedfulthings.com/?page_id=281

# Start of Settings
# Report on MAPI Latency >= x milliseconds
$MinLatency=0
# End of Settings

# Changelog
## 2.0 : Initial Release
## 2.1 : Allow for multiple server roles on the same box
## 2.2 : Add Server name filter
## 2.3 : Fix server name filter
## 2.4 : Allow Exchange version 15

$latencyMS = @{Name="Latency (mS)";expression={[Math]::Round(([TimeSpan] $_.Latency).TotalMilliSeconds)}}
If ($2007Snapin -or $2010Snapin) {
  $exServers = Get-MailboxServer -ErrorAction SilentlyContinue |
    Where { $_.AdminDisplayVersion -match "^Version (8|14|15)" -and $_.Name -match $exServerFilter } |
	Sort Name
  If ($exServers -ne $null) {
    ForEach ($server in $exServers) {
      $MAPIResults = Test-MAPIConnectivity -Server $Server |
	    Sort Server,Database |
        Select Server,Database, Result, $LatencyMS, Error
	  $MAPIResults |
	    Where { $_."Latency (mS)" -ge $MinLatency } |
	    Select Server,Database, Result, "Latency (mS)", Error
	}
  }
}

$Title = "Exchange 20xx MAPI Connectivity"
$Header =  "Exchange 20xx MAPI Connectivity"
$Comments = "Exchange 20xx MAPI Connectivity"
If ($MinLatency -gt 0) {
  $Header += " where Latency >= $($MinLatency)mS"
}
$Display = "Table"
$Author = "Phil Randal"
$PluginVersion = 2.4
$PluginCategory = "Exchange2010"
