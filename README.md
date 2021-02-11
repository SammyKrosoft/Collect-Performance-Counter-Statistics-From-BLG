# Collect-Performance-Counter-Statistics-From-BLG
This script gets the counters list from a BLG you specify.
If not specified, it will look for an Exchange DailyDiagnostics folder :

```powershell
$($env:exchangeinstallpath)Logging\Diagnostics\DailyPerformanceLogs\
```

The output is a file saved by detault on the current user's default Documents folder with a date-time stamp suffix:
```powershell
$($env:USERPROFILE)\Documents\CountersSummary_$(Get-Date -Format yyyMMdd_hhmmss).csv
```

The output is a CSV file containing the counter full path, the number of samples, the Min, Average, Max values for each counter.

For Exchange, you can see the following pages for the thresholds:
[Exchange 2013 (valid for Exchange 2016 and Exchange 2019 !) performance counters](https://docs.microsoft.com/en-us/exchange/exchange-2013-performance-counters-exchange-2013-help)
[My TechNet blog post about Exchange 2013 summarized counters, also still valid for Exchange 2016 and Exchange 2019 !](https://docs.microsoft.com/en-us/archive/blogs/samdrey/exchange-2013-performance-counters-and-their-thresholds)
