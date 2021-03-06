$Title = "Exchange 20xx Services"
$Header = "Exchange 20xx Services"
$Comments = "Exchange Services"
$Display = "None"
$Author = "Phil Randal"
$PluginVersion = 2.1
$PluginCategory = "Exchange2010"

# Based on code in http://www.powershellneedfulthings.com/?page_id=281

# Start of Settings
# Exchange Services - Only report on those in an unexpected state
$ReportUnexpectedOnly=$false
# End of Settings

# Changelog
## 2.0 : Initial implementation
## 2.1 : Add Server name filter

If ($2007Snapin -or $2010Snapin) {
  $exServers = Get-ExchangeServer -ErrorAction SilentlyContinue |
    Where { $_.IsExchange2007OrLater -eq $True -and $_.Name -match $exServerFilter } |
	Sort Name
  ForEach ($Server in $exServers) {
	$Target = $Server.Name
    Write-CustomOut "...Collating Service Details for $Target"
	$ListOfServices = (gwmi -computer $Target -query "select * from win32_service where Name like 'MSExchange%' or Name like 'IIS%' or Name like 'SMTP%' or Name like 'POP%' or Name like 'W3SVC%'")
	$Services = @()
	Foreach ($Service in $ListOfServices){
		$Details = "" | Select Name,Account,"Start Mode",State,"Expected State"
		$Details.Name = $Service.Caption
		$Details.Account = $Service.Startname
		$Details."Start Mode" = $Service.StartMode
		$Details.State = $Service.State
		$Details."Expected State" = "OK"
		
		If ($Service.StartMode -eq "Auto" -and $Service.State -eq "Stopped") {
			$Details."Expected State" = "Unexpected"
		}
		ElseIf ($Service.StartMode -eq "Disabled" -and $Service.State -eq "Running") {
			$Details."Expected State" = "Unexpected"
		}

		If (!$ReportUnexpectedOnly -or $Details."Expected State" -ne "OK") {
		  $Services += $Details
		}
	}
	If ($Services -ne $null) {
	  $Header = "Exchange Services on $Target"
      If ($ReportUnexpectedOnly) {
	    $Header += " which are not in their expected state"
	  }
	  $script:MyReport += Get-CustomHeader $Header $Comments
      $script:MyReport += Get-HTMLTable ($Services)
      $script:MyReport += Get-CustomHeaderClose
	}
  }
}
$Services=$null

