############################################################################################################
### File copy and scheduled task creation for Entra/Intune lock screen enrollmentStatus Script
### Mike O'Leary | mikeoleary.net | @cmtrace-dot-exe 
############################################################################################################

param (
        [int] $repetitionInterval = 5,
		[switch] $log,
		[string] $logPath = "$env:public\enrollmentStatus\$env:computername.log",
		[string] $stagingDirectory = "$env:public\enrollmentStatus"
    )

# trim any trailing backslashes from $stagingDirectory so things don't go kablooie
	$stagingDirectory = $stagingDirectory.trimend("\")
# copy enrollmentStatus files to staging directory 
	xcopy "$PSScriptRoot\enrollmentStatus" $stagingDirectory /e /s /y /h /i
# change default lock screen image permissions
	takeown /f $env:windir\web\Screen\img100.jpg
	icacls $env:windir\web\Screen\img100.jpg /Grant 'System:(F)'
# preserve original lockscreen for later restoration
	copy-item "$env:windir\web\screen\img100.jpg" -destination "$stagingDirectory\originalLockScreen.jpg" -force
# replace default logon screen wallpaper with first enrollment status jpg
	# copy-item "$PSScriptRoot\enrollmentStatus\doNotUseEnrollmentPending_01.jpg" -destination "$env:windir\web\screen\LockScreen.jpg" -force
	copy-item "$PSScriptRoot\enrollmentStatus\doNotUseEnrollmentPending_01.jpg" -destination "$env:windir\web\screen\img100.jpg" -force
# check for presence of registry paths, create if not present
	if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization")) { New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"}
	if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP")) { New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"}
# create lockscreen registry entries
	New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "LockScreenImage" -Value "$env:windir\Web\Screen\img100.jpg" -PropertyType String -Force
	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name "LockScreenImagePath" -Value "$env:windir\Web\Screen\img100.jpg" -PropertyType String -Force
	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name "LockScreenImageUrl" -Value "$env:windir\Web\Screen\img100.jpg" -PropertyType String -Force
	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name "LockScreenImageStatus" -Value "1" -PropertyType DWord -force

# create 'step.txt' file and write current step for later reference
	"01" | Set-Content "$stagingDirectory\step.txt"

# Create enrollmentStatus scheduled task, firing at interval defined in $repetitionInterval

	# Create a new task action
		if ($log) {
			$taskAction = New-ScheduledTaskAction `
				-WorkingDirectory "$env:windir\system32\windowspowershell\v1.0" `
				-Execute "Powershell.exe" `
				-Argument $("-NoProfile -ExecutionPolicy Bypass -File $stagingDirectory\enrollmentStatus.ps1 -stagingDirectory $stagingDirectory -log -logPath $logPath")
		}
		elseif (-not $log) {
			$taskAction = New-ScheduledTaskAction `
				-WorkingDirectory "$env:windir\system32\windowspowershell\v1.0" `
				-Execute "Powershell.exe" `
				-Argument $("-NoProfile -ExecutionPolicy Bypass -File $stagingDirectory\enrollmentStatus.ps1 -stagingDirectory $stagingDirectory")
			}
	
	# create task trigger/schedule
		$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $repetitionInterval)

	# The name of the scheduled task.
		$taskName = "enrollmentStatus"

	# Describe the scheduled task.
		$description = "Scheduled Task to display current Entra and Intune enrollment status on the lock screen."

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
