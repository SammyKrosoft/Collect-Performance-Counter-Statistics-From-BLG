[CmdletBinding(DefaultParameterSetName="ParamArrayFilter")]
Param([Parameter()][string]$PerfFileFolder = "C:\temp\Perf\46_Full_000003",
      [Parameter()][string]$PerfFileName = "46_Full_000003.blg",
      [Parameter()][string]$TargetCsvFileName = "Perfs_$(get-date -format ddMMMyyyy_mmHHss).csv",
      [Parameter()][string]$CounterListFileName = "Counters.txt"
        )

# Path and name of the BLG file to convert to CSV
#$PerfFileFolder = "C:\temp\Perf\46_Full_000003"
#$PerfFileName = "46_Full_000003.blg"
#Testing if $PerfFileFolder ends with a backslash or not. If not, we add it.
If (-not ($PerfFileFolder -match '\\$')){
    $PerfFileFolder = $PerfFileFolder + '\'
}
$FullPerfFilePath = $PerfFileFolder + $PerfFileName


# File Name of the converted CSV file
#$TargetCsvFileName = "Perfs_$(get-date -format ddMMMyyyy_mmHHss).csv"

# Script Directory
$ScriptDir = $PSScriptRoot

# Counter list file name
#$CounterListFileName = "Counters.txt"



$ValidatePaths = Test-Path $PerfFileFolder,$FullPerfFilePath,"$ScriptDir\$CounterListFileName"
$AllPathsValid = $True
For ($i=0;$i -lt $ValidatePaths.Length;$i++) {
    Write-Host "$i - $($ValidatePaths[$i])"
    Switch ($i) {

        0 {if (!$($ValidatePaths[$i])) {Write-Host "PerfFileFolder invalid";$AllPathsValid = $False}}
        1 {if (!$($ValidatePaths[$i])) {Write-Host "Full Perf File Path invalid";$AllPathsValid = $False}}
        2 {if (!$($ValidatePaths[$i])) {Write-Host "CounterListFile invalid";$AllPathsValid = $False}}

    }

}

If ($AllPathsValid -eq $False){Write-Host "Fix the above directory and relaunch script"}Else {
    # relog.exe $TargetPerfFile -f csv -o $TargetCsvFileName -y -cf $ScriptDir\CounterList3.txt
    relog.exe $FullPerfFilePath -f csv -o "$ScriptDir\$TargetCsvFileName" -y -cf "$ScriptDir\$CounterListFileName"
}