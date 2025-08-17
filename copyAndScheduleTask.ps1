# copy enrollmentStatus files to public user folder
	xcopy "$PSScriptRoot\enrollmentStatus" "$env:public\enrollmentStatus" /e /s /y /h /i
# preserve original lockscreen for later restoration
	copy-item "$env:windir\web\screen\LockScreen.jpg" -destination "$env:public\enrollmentStatus\originalLockScreen.jpg"
# replace default logon screen wallpaper with first enrollment status jpg
	copy-item "$PSScriptRoot\enrollmentStatus\doNotUseEnrollmentPending_01.jpg" -destination "$env:windir\web\screen\LockScreen.jpg"
# create 'step.txt' file and write current step for later reference
	"01" | Set-Content "$env:public\enrollmentStatus\step.txt"

# Create enrollmentStatus scheduled task, firing at a five minute interval
	# Create a new task action
		$taskAction = New-ScheduledTaskAction `
			-WorkingDirectory "$env:public\enrollmentStatus" `
			-Execute "enrollmentStatus.bat"

	# create task trigger/schedule
		$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 05)

	# The name of the scheduled task.
		$taskName = "enrollmentStatus"

	# Describe the scheduled task.
		$description = "Scheduled Task to display current Entra and Intune enrollment status on the login screen."

	# create settings set
		$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8
		
	# specifiy task principal	
		$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
			#-RunLevel Highest `

	# Register the scheduled task
		Register-ScheduledTask `
			-TaskName $taskName `
			-Action $taskAction `
			-Trigger $taskTrigger `
			-Description $description `
			-Settings $settings `
			-Principal $principal
