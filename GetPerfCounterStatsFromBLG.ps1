
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

#Loading all counters present in the target BLG:
#$counterList = @(Import-Counter -path $env:exchangeinstallpath\Logging\Diagnostics\DailyPerformanceLogs\ExchangeDiagnosticsDailyPerformanceLog_02071407.blg -ListSet * | ForEach-Object {$_.Paths})
$counterList = @(Import-Counter -path $env:exchangeinstallpath\Logging\Diagnostics\DailyPerformanceLogs\ExchangeDiagnosticsDailyPerformanceLog_02071407.blg -ListSet * | Foreach-Object {If ($_.CounterSetType -eq "SingleInstance"){$_.Paths} Else {$_.PathsWithInstances}})

# To load all counters list from all BLGs in the DailyPerformanceLogs Exchange install folders:
#$counterList = @(Import-Counter -ListSet $env:exchangeinstallpath\Logging\Diagnostics\DailyPerformanceLogs\*.blg)
$Counter = "*I/O Database Reads (Attached) Average Latency*"
$CounterInstance = "*DAG1-DB*"
#$Server = "E2016-02"

#$counterListFiltered = $counterList -like "\\$Server\$Counter" 
$counterListFiltered = $counterList -like "$Counter" 
$counterListFiltered = $counterListFiltered -like "$CounterInstance"
$counterListFiltered


#To import counters from all the BLGs in the DailyPerformanceLogs:
#$Data = Import-Counter -Path $env:exchangeinstallpath\Logging\Diagnostics\DailyPerformanceLogs\*.blg -Counter $counterListFiltered
#To import counters from only one BLG file in the DailyPerformanceLogs:
$Data = Import-Counter -Path $env:exchangeinstallpath\Logging\Diagnostics\DailyPerformanceLogs\ExchangeDiagnosticsDailyPerformanceLog_02071407.blg -Counter $CounterListFiltered

$StopWatch.Stop()
$StopWatch.Elapsed.totalseconds | Out-Host


$Data | fl *
$Data | Select -ExpandProperty CounterSamples | Group-Object Path | Foreach {$_.Name;$_ | Select -ExpandProperty Group | Measure-Object -average -min -max CookedValue}



