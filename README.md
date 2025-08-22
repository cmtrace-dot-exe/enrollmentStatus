
copyAndScheduleTask.ps1 optional parameters:
```
-log switch 
 [Default: disabled]
 Enables optional logging.

-logpath string 
 [Default: $env:public\enrollmentStatus\$env:computername.log]
 Path and name of optional log.

-repetitionInterval int 
 [Default: 5]
 Number of minutes to wait between each run of the scheduled task.

-stagingDirectory string
 [Default: "$env:public\enrollmentStatus"]
 Local staging directory for enrollmentStatus.ps1 and lock screen wallpaper.
```
