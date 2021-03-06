# based on http://www.mikepfeiffer.net/2010/03/exchange-2010-database-statistics-with-powershell/

# Start of Settings
# Report on the largest mailboxes - number to report on (if <= 0, will report on whole database)
$NumLargeMailboxes=10
# Is the Large Mailbox Report per Database?
$LargeMailboxReportPerDatabase=$False
# Minimum Mailbox Size to report on (in MB)
$MinMailboxSize=0
# Exchange Database Name Filter (Largest) (regular expression, to select all use '.*')
$exDBFilter=".*"
# End of Settings

# Changelog
## 2.0 : Sort by Server and Database Name
##       Include Server Name in Heading
##       Add Exchange 2007 support
##       Show deleted items count and size in report
## 2.1 : Change comments
## 2.2 : Place comments at end of script
## 2.3 : Add Server name filter
## 2.4 : Add database name filter

$Title = "Exchange 20xx Largest Mailboxes"
$Author = "Phil Randal"
$Comments = "Mailboxes sorted by descending mailbox size"
$PluginVersion = 2.2
$PluginCategory = "Exchange2010"

function Get-DatabaseLargeMailboxes {
  $Databases = Get-MailboxDatabase -Status -ErrorAction SilentlyContinue |
    Where { $_.Server -match $exServerFilter } |
	Where { $_.Name -match $exDBFilter } |
    Sort Server,Name
  If ($Databases) {
    foreach ($Database in $Databases) {
      If ($Database.DatabaseCreated) {
        $Details=Get-Mailbox -Database $Database -Resultsize Unlimited |
          Where { $_.Server -match $exServerFilter } |
	      Get-MailboxStatistics |
   		  Where {$_.totalitemsize -ge $MBSize} |
		  Sort TotalItemSize -descending |
		  Select DisplayName,
		    ServerName,
		    ItemCount,
		    @{name="Mailbox Size (MB)";exp={$_.totalitemsize.value.ToMB()}},
		    DeletedItemCount,
		    @{name="Deleted Items Size (MB)";exp={$_.totaldeleteditemsize.value.ToMB()}},
		    @{name="Total Mailbox Size (MB)";exp={$_.totalitemsize.value.ToMb()+$_.totaldeleteditemsize.value.ToMb()}} @Selection
        If ($null -ne $Details) {
          $Header =  "Largest Mailbox Sizes on $($Database.Server) $($Larger)in $Database sorted by descending size"
          $script:MyReport += Get-CustomHeader $Header $Comments
	      $script:MyReport += Get-HTMLTable $Details
          $script:MyReport += Get-CustomHeaderClose
		}
	  }
	}
  }
}

If ($2007Snapin -or $2010Snapin) {
  $Larger = ""
  $MBSize = $MinMailboxSize * 1MB
  If ($MBSize -gt 0) {
    $Larger = "larger than $MinMailboxSize MB "
  }
  $Selection = @{}
  If ($NumLargeMailboxes -gt 0) {
    $Selection = @{ First = $NumLargeMailboxes }
  }
  If ($LargeMailBoxReportPerDatabase) {
    $Display = "None"
    Get-DatabaseLargeMailboxes
  } Else {
    $Display = "Table"
    $Header = "Mailboxes with Mailbox Size $($Larger)sorted by descending size"
    Get-Mailbox -Resultsize Unlimited |
      Where { $_.ServerName -match $exServerFilter } |
	  Get-MailboxStatistics |
	  Where {$_.totalitemsize -gt $MBSize} |
      Sort TotalItemSize -descending |
      Select DisplayName,
	    ServerName,
	    DatabaseName,
		ItemCount,
		@{name="Mailbox Size (MB)";exp={$_.totalitemsize.value.ToMB()}},
		DeletedItemCount,
		@{name="Deleted Items Size (MB)";exp={$_.totaldeleteditemsize.value.ToMB()}},
        @{name="Total Mailbox Size (MB)";exp={$_.totalitemsize.value.ToMb()+$_.totaldeleteditemsize.value.ToMb()}} @Selection
  }
}
$Comments = "Mailboxes sorted by descending mailbox size"
