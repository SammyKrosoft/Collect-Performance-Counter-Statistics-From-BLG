<#
.DESCRIPTION
      This script analyses the counters we find with substrings (example: you are looking for Available Memory stats like Min, Avg, Max on a BLG,
      but don't know the exact counter name, you'll use the -ArrayFilter parameter with an array of substrings like "Memory", "Available" to find 
      all counters within the BLG you specify that have these words in their path. On this example, it's "\\ServerName\Memory\Available MBytes" counter.

.EXAMPLE
      Get-BLGSummarizedPerfmonCounterStats.ps1 -BLGFolder "C:\temp\" -ArrayFilter "I/O Database Reads (Attached) Average Latency", "DB"
      Because we didn't specify the -BLGFileName, that Will analyze the oldest BLG file found on C:\temp\, and dump the Min, Avg, Max values for all the "I/O Database Reads (Attached)
      Average Latency" counters for all the databases with "DB" in their full counter path names.

.NOTES
      Common counter substrings to search for:
        -ArrayFilter "I/O Database Reads (Attached) Average Latency"
        -ArrayFilter "Memory", "Available MBytes"
        -ArrayFilter "% processor time", "Total"
        -ArrayFilter "domain controllers", "ldap", "time"
        
#>

[CmdletBinding(DefaultParameterSetName="ParamArrayFilter")]
Param([Parameter()][string]$BLGFileName,
      [Parameter(ParameterSetName="ParamArrayFilter")][string[]]$ArrayFilter,
      [Parameter(ParameterSetName="ParamFile")][string]$CountersFile, #Note: Haven't tested the -CountersFile feature yet
      [Parameter()][string]$BLGFolder = "$($env:exchangeinstallpath)Logging\Diagnostics\DailyPerformanceLogs\"
      )

#Setting up global variables that we'll reuse
#Output file to local user launching the script's "My Documents" folder
$OutputFile = "$($env:USERPROFILE)\Documents\CountersSummary_$(Get-Date -Format yyyMMdd_hhmmss).csv"

# Defining and starting stopwatch to measure script execution time
Write-host "Starting..." -ForegroundColor Green
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

If (!(Test-Path $BLGFolder)){
      Write-Host "Folder $BLGFolder doesn't exist ... please run the script from an Exchange server which DailyPerformanceLogs folder is located in the Exchange Install path\Logging\Diagnostics folder, or specify an existing folder with .BLG files on it" -ForegroundColor Red
      $StopWatch.Stop();
      $StopWatch.Elapsed.totalseconds | Out-Host
      Exit
}

If ([String]::IsNullOrEmpty($BLGFileName)){
      $BLGFileName = (Get-ChildItem -Path "$BLGFolder\*.blg" | Sort-Object LastWriteTime | Select -First 1).Name
      }

      Write-Host "Current Parameters" -ForegroundColor Yellow -BackgroundColor Blue
      Write-host "BLG File          :     $BLGFileName" -ForegroundColor Yellow
      Write-Host "BLG folder path   :     $BLGFolder" -ForegroundColor Yellow
      Write-Host "User Parameter Set:     $($PSCmdlet.ParameterSetName)" -ForegroundColor Yellow

#region BLG file check
#Verifying if BLG file(s) exist - doesn't apply if no BLG specified, as took the oldest one
$BLGDiagnosticsFilesPath = "$BLGFolder\$BLGFileName"
If (!(Test-Path $BLGDiagnosticsFilesPath)){
      Write-Host "File(s) $BLGDiagnosticsFilesPath not found. Please specify valid BLG file" -ForegroundColor Red;
      $StopWatch.Stop();
      $StopWatch.Elapsed.totalseconds | Out-Host
      exit;
}

#endregion BLG file check

If ($CountersFile){
      #Validate the file exists
      if (!(Test-Path($CountersFile))){
            Write-Host "The file $CountersFile doesn't exist ! Specify a valid file or use -CounterFilterX to search for counters..." -ForegroundColor Red -BackgroundColor Blue
            $StopWatch.Stop();
            $StopWatch.Elapsed.totalseconds | Out-Host
            Exit
      } Else {
            Write-Host "File $CountersFile found, loading counters from file..." -ForegroundColor Green
            $CountersListFromFile = Get-Content $CountersFile
      }
} Else {
      If ([string]::IsNullOrEmpty($ArrayFilter)){
            $ArrayFilter = "*"
            Write-Host "No CountersFile and no ArrayFilter specified... using ArrayFilter = $ArrayFilter"
      } Else {
            $NbFilterStrings = $ArrayFilter.Count
            for ($i=0;$i -lt $NbFilterStrings;$i++) {
                  Write-Host "Treating Index of ArrayFilter #$i aka $($ArrayFilter[$i])"
                  $ArrayFilter[$i]="*" + $ArrayFilter[$i] + "*"
            }
      }
}

#Loading all counters present in the target BLG:
Write-Host "Loading counters list from BLG file, please wait..." -ForegroundColor DarkRed
#$CounterList = @(Import-Counter -path "$BLGDiagnosticsFilesPath" -ListSet * | Foreach-Object {If ($_.CounterSetType -eq "SingleInstance"){$_.Paths} Else {$_.PathsWithInstances}})
$CounterList = @(Import-Counter -path "$BLGDiagnosticsFilesPath" -ListSet * | Foreach-Object {If ($_.CounterSetType -eq "SingleInstance"){$_ | Select -ExpandProperty Paths} Else {$_ | Select -ExpandProperty PathsWithInstances}})

$Tick = $StopWatch.Elapsed.totalseconds
Write-host "Took $Tick seconds to load all counters from $BLGFileName"
Write-Host "Found $($CounterList.count) counter(s) !" -ForegroundColor DarkRed -BackgroundColor DarkBlue
Write-Host "Counters path loaded ! Filtering these as per ArrayFilter or Counters from file..." -ForegroundColor DarkRed

$CounterListFiltered = $CounterList

If ($CountersFile){
      $CounterListFiltered = $CountersListFromFile
}ElseIf (!($ArrayFilter -eq "*")){
      Foreach ($Item in $ArrayFilter){
            Write-Host "Filtering with $Item" -ForegroundColor Yellow
            $CounterListFiltered = $CounterListFiltered | ? {$_ -like $Item}
      }
}Else{
      Write-Host "-ArrayFilter is unspecified, using ArrayFilter = $ArrayFilter"
      $CounterListFiltered = $CounterList
}

$NumberOfCountersFromBLG = $CounterListFiltered.count

If ($NumberOfCountersFromBLG -eq 0){
      Write-Host "No counters found with the chosen filter or counter files"
}

Write-Host "List of counters filtered:"
Foreach ($item in $CounterListFiltered){
      write-host $Item -ForegroundColor Green
}

#import counters this time not only the paths, but all the values as well, for filtered counters 
$Data = Import-Counter -Path "$BLGDiagnosticsFilesPath" -Counter $CounterListFiltered -ErrorAction SilentlyContinue

$AllResults = @()
$Data | Select -ExpandProperty CounterSamples | Group-Object Path | Foreach {   $Stats = $_ | Select -ExpandProperty Group | Measure-Object -Average -Minimum -Maximum CookedValue
                                                                                $AllResults += [PSCustomObject]@{
                                                                                Counter=$_.Name
                                                                                Instance = $_.Group.InstanceName[0]
                                                                                Minimum=$Stats.Minimum
                                                                                Average=$Stats.Average
                                                                                Maximum=$Stats.Maximum
                                                                                Samples=$Stats.Count
                                                                                                                  }                                                                                        
                                                                            }
$StopWatch.Stop()
$FinalTime = $StopWatch.Elapsed.totalseconds

Write-Host "Took $FinalTime seconds in total to run the script"

$AllResults | Select Counter, Samples, Instance, Minimum, Average, Maximum | Export-CSV -NoTypeInformation -Path $OutputFile
notepad $OutputFile
