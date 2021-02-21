# Get-BLGSummarizedPerfmonCounterStats.ps1

## Intro
This script gets the counters list from a BLG you specify.
If ```-BLGFileName``` is not specified, it will look for an Exchange DailyPerformanceDiagnostics folder :

```powershell
$($env:exchangeinstallpath)Logging\Diagnostics\DailyPerformanceLogs\
```

The output is a file saved by detault on the current user's default Documents folder with a date-time stamp suffix:
```powershell
$($env:USERPROFILE)\Documents\CountersSummary_$(Get-Date -Format yyyMMdd_hhmmss).csv
```

The output is a CSV file containing the counter full path, the number of samples, the Min, Average, Max values for each counter.

## Examples

### Sample usage 1:

```powershell
Get-BLGSummarizedPerfmonCounterStats.ps1 -CounterFilter1 "Memory" -CounterFilter2 "Available" -ExchangeBLGDiagnosticsFolder "c:\temp"
```
Since the ```-BLGFileName``` is not specified, but the ```-ExchangeBLGDiagnosticsFolder``` is specified as ```"C:\temp"```, this will get the **oldest BLG file** on the *C:\temp* folder to collect the statistics of the counters that have *"Memory"* and *"Available"* in their names, which I already know we have only *\Memory\Available MBytes* falling into this filter, hehe.

### Sample usage 2:

```powershell
.\Get-BLGSummarizedPerfmonCounterStats.ps1 -CounterFilter1 "Memory" -CounterFilter2 "Available" -ExchangeBLGDiagnosticsFolder "C:\temp" -BLGFileName *.blg
```
Here we specified the ```-BLGFileName``` as ```*.blg``` as well as the ```-ExchangeBLGDiagnosticsFolder``` specified as ```"C:\temp"``` and this will get all the counters (```*.blg```) that have *"Memory"* and *"Available"* in their names, and that we copied on the ```c:\temp``` directory prior to running the script.

### Sample output:

```output
"Counter","Samples","Minimum","Average","Maximum"
"\\e2016-02\memory\available mbytes","384","0","909.041666666667","1366"
"\\e2016-01\memory\available mbytes","384","0","419.817708333333","582"
```

That you can import to Excel or even using Import-CSV:

```powershell
Import-CSV .\CountersSummary_20210211_053711.csv | ft
```

And you will have a nicer view on Powershell and you can work with counters to get specific values and compare to thresholds:

```output
Counter                            Samples Minimum Average          Maximum
-------                            ------- ------- -------          -------
\\e2016-02\memory\available mbytes 384     0       909.041666666667 1366
\\e2016-01\memory\available mbytes 384     0       419.817708333333 582
```

## Links

For Exchange, you can see the following pages for the thresholds - right-click "Open on a new tab" to keep this Github tab open):

- [Exchange 2013 (valid for Exchange 2016 and Exchange 2019 !) performance counters](https://docs.microsoft.com/en-us/exchange/exchange-2013-performance-counters-exchange-2013-help)

- [My TechNet blog post about Exchange 2013 summarized counters, also still valid for Exchange 2016 and Exchange 2019 !](https://docs.microsoft.com/en-us/archive/blogs/samdrey/exchange-2013-performance-counters-and-their-thresholds)
