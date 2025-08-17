############################################################################################################
### Entra/Intune enrollmentStatus Script
### olearym
###
############################################################################################################


	# Configure and start logging
	$LogFile = "$env:public\enrollmentStatus\$env:computername.log"

	# configure logging if $logfile variable was provided, log nothing if not
	if ($LogFile) {
		Function LogWrite ([string]$logstring) {Add-Content -Path $LogFile -Value $logstring}
	} 
	else {
		Function LogWrite ([string]$logstring) {
			# Logging disabled, do nothing
		}
	}

	logwrite $(get-date), "-------------------------------"

	# Switch to High Performance Power Plan to prevent interruption of onboarding workflow
	powercfg /S 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

	##################################################################
	# evaluate and act upon entra join & intune enrollment condition #
	##################################################################
	
	
	# parse and ingest dsregcmd output into an object
		$dsregcmd = New-Object PSObject ; Dsregcmd /status | Where {$_ -match ' : '}|ForEach {$Item = $_.Trim() -split '\s:\s'; $Dsregcmd|Add-Member -MemberType NoteProperty -Name $($Item[0] -replace '[:\s]','') -Value $Item[1] -EA SilentlyContinue}

	# check if device is Entra joined
		if ($dsregcmd.AzureAdJoined -eq 'YES') {
			logwrite $(get-date), "Entra Joined: YES"
			
			# check intune $EnrollmentKey in registry and take action if entra joined + intune enrolled
				$EnrollmentKey = Get-Item -Path HKLM:\SOFTWARE\Microsoft\Enrollments\* | Get-ItemProperty | Where-Object -FilterScript {$null -ne $_.UPN}	
				if($($EnrollmentKey) -and $($EnrollmentKey.EnrollmentState -eq 1)){
					logwrite $(get-date), "Intune Enrolled: YES"
					logwrite $(get-date), "Deleting enrollmentStatus Task..."
					
					# remove enrollmentStatus scheduled task
					Unregister-ScheduledTask -TaskName "enrollmentStatus" -Confirm:$false
		
					# restore power management scheme to balanced
					powercfg /S SCHEME_BALANCED

					# return lockscreen image to normal
					copy-item "$env:public\enrollmentStatus\originalLockScreen.jpg" -destination "$env:windir\web\screen\LockScreen.jpg"
					Restart-Computer -force
				}
				else {
					# if entra joined but not intune enrolled, check value stored in 'step.txt' and change lock screen wallpaper if value is NOT "02"
					if($(get-Content "$env:public\enrollmentStatus\step.txt") -NE "02"){ 
						logwrite $(get-date), "Intune Enrolled: NO"
						logwrite $(get-date), "Creating SCCM policy reset scheduled task and restarting computer..."
					
						# copy DO NOT USE step 02 wallpaper to lockscreen, iterate 'step.txt' and restart
						copy-item "$PSScriptRoot\doNotUseEnrollmentPending_02.jpg" -destination "$env:windir\web\screen\LockScreen.jpg"
						# iterate step.txt file
						"02" | Set-Content "$env:public\enrollmentStatus\step.txt"
						
						Restart-Computer -force
						exit
			}
			logwrite $(get-date), "Intune Enrolled: NO"
		}
	}
	else {
		logwrite $(get-date), "Entra Joined: NO"
	}