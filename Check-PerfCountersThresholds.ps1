

$counterStatsFile = (Get-ChildItem .\CountersSummary*.csv | Sort-Object LastWriteTime -Descending| Select -First 1).name
If ([string]::IsNullOrEmpty($counterStatsFile){
    Write-Host "Please specify a valid -CounterStatsFile or ensure you have a CSV file starting with CountersSummary that's an output from the Collect-SummarizedPerfmonCounterStats.ps1 script in the current directory" -ForegroundColor Red
    return
} Else { 
    $CounterStats = Import-CSV $counterStatsFile
}

$CounterStats | Foreach {
    Switch ($_.Counter) {
        
    }
    If ($_.Counter -match "Available mbytes"){Write-Host "Memory Counter => $_.Counter" -ForegroundColor Green}
    If ($_.Minimum -lt 100){Write-Host "Memory counter on error threshold <100 !" -ForegroundColor red}
}