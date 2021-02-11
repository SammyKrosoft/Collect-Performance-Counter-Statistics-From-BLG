[CmdletBinding()]
Param([string]$BLGFileName,
      [string]$CounterFilter1="I/O Database Reads (Attached) Average Latency",
      [string]$CounterFilter2,
      [string]$CounterFilter3,
      [string]$ExchangeBLGDiagnosticsFolder = "$($env:exchangeinstallpath)Logging\Diagnostics\DailyPerformanceLogs\"
      )

#Setting up global variables that we'll reuse
$OutputFile = "$($env:USERPROFILE)\Documents\CountersSummary_$(Get-Date -Format yyyMMdd_hhmmss).csv"

# Defining and starting chronograph
Write-host "Starting..." -ForegroundColor Green
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()


Write-Host "Current Parameters:" -ForegroundColor Green
Write-host "BLG File          :     $BLGFileName" -ForegroundColor Yellow
Write-Host "BLG folder path   :     $ExchangeBLGDiagnosticsFolder" -ForegroundColor Yellow
Write-Host "Counter Filter 1  :     $CounterFilter1" -ForegroundColor Yellow
Write-Host "Counter Filter 2  :     $CounterFilter2" -ForegroundColor Yellow
Write-Host "Counter Filter 3  :     $CounterFilter3" -ForegroundColor Yellow

# If there is nothing on the CounterFilter parameters, we consider a wildcard, otherwise, we add wildcards to find counters with substrings <3
If ([String]::IsNullOrEmpty($BLGFileName)){
    $BLGFileName = (Get-ChildItem $ExchangeBLGDiagnosticsFolder | Sort-Object LastWriteTime | Select -First 1).Name
    }
If ([string]::IsNullOrEmpty($CounterFilter1)){$CounterFilter1 = "*"}else{$CounterFilter1 = "*" + $CounterFilter1 + "*"}
If ([string]::IsNullOrEmpty($CounterFilter2)){$CounterFilter2 = "*"}else{$CounterFilter2 = "*" + $CounterFilter2 + "*"}
If ([string]::IsNullOrEmpty($CounterFilter3)){$CounterFilter3 = "*"}else{$CounterFilter3 = "*" + $CounterFilter3 + "*"}

Write-Host "Processed filters:" -ForegroundColor Green
Write-Host "BLG file (if nothing specified, takes the oldest):" -ForegroundColor Magenta
Write-host "                        $BLGFileName"
Write-Host "BLG Folder Path   :     $ExchangeBLGDiagnosticsFolder" -ForegroundColor Magenta
Write-Host "Counter Filter 1  :     $CounterFilter1" -ForegroundColor Magenta
Write-Host "Counter Filter 2  :     $CounterFilter2" -ForegroundColor Magenta
Write-Host "Counter Filter 3  :     $CounterFilter3" -ForegroundColor Magenta

#Verifying if BLG file(s) exist - doesn't apply if no BLG specified, as took the oldest one
$ExchangeBLGDiagnosticsFilesPath = "$ExchangeBLGDiagnosticsFolder\$BLGFileName"
If (!(Test-Path $ExchangeBLGDiagnosticsFilesPath)){Write-Host "File(s) $ExchangeBLGDiagnosticsFilesPath not found. Please specify valid BLG file" -ForegroundColor Red;exit;$StopWatch.Stop();$StopWatch.Elapsed.totalseconds | Out-Host}


#Loading all counters present in the target BLG:
Write-Host "Getting counters list from BLG file, please wait..." -ForegroundColor DarkRed
$counterList = @(Import-Counter -path "$ExchangeBLGDiagnosticsFilesPath" -ListSet * | Foreach-Object {If ($_.CounterSetType -eq "SingleInstance"){$_.Paths} Else {$_.PathsWithInstances}})

$Tick = $StopWatch.Elapsed.totalseconds
Write-host "Took $Tick seconds to load all counters from $BLGFileName"

Write-Host "All counters loaded $($CounterList.Count) counters, now filtering ..." -ForegroundColor DarkRed
#$counterListFiltered = $counterList -like "\\$Server\$Counter" 
$counterListFiltered = $counterList -like "$CounterFilter1"
$counterListFiltered = $counterListFiltered -like "$CounterFilter2"
$CounterListFiltered = $counterListFiltered -like "$CounterFilter3"

If ($counterListFiltered -eq 0){
    Write-Host "no counters found with the filters provided. Exiting...";
    $StopWatch.Stop()
    $StopWatch.Elapsed.totalseconds | Out-Host
    exit
}
Else {
    write-Host "Counters filtered, we have now $($counterListFiltered.count) counters:" -ForeGroundColor yellow -BackgroundColor Blue
    Foreach ($Item in $counterListFiltered){Write-Host $Item -Foregroundcolor yellow -BackgroundColor Blue}
}

#To import counters from all the BLGs in the DailyPerformanceLogs:
#To import counters from only one BLG file in the DailyPerformanceLogs:
$Data = Import-Counter -Path "$ExchangeBLGDiagnosticsFilesPath" -Counter $CounterListFiltered -ErrorAction SilentlyContinue

$AllResults = @()
$Data | Select -ExpandProperty CounterSamples | Group-Object Path | Foreach {   $Stats = $_ | Select -ExpandProperty Group | Measure-Object -Average -Minimum -Maximum CookedValue
                                                                                $AllResults += [PSCustomObject]@{
                                                                                                                    
                                                                                                                    Counter=$_.Name
                                                                                                                    Minimum=$Stats.Minimum
                                                                                                                    Average=$Stats.Average
                                                                                                                    Maximum=$Stats.Maximum
                                                                                                                    Samples=$Stats.Count
                                                                                                                    }                                                                                        
                                                                            }
$StopWatch.Stop()
$FinalTime = $StopWatch.Elapsed.totalseconds

Write-Host "Took $FinalTime seconds in total to run the script"

$AllResults | Select Counter, Samples, Minimum, Average, Maximum | Export-CSV -NoTypeInformation -Path $OutputFile
notepad $OutputFile
