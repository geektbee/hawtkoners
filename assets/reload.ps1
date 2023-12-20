# Script to stop current HKT Process ID, so the program can start back up.

# Check if there's already a processes file for us.
# If there is not a file, make it.
If (!(Test-Path "$($ENV:hktPids)")) {
	# If there's no folder in the first place....
	If (!(Test-Path "$($ENV:hktAppDataPath)")) {
		# ....create the folder.
		New-Item -ItemType Directory -Path "$($ENV:hktAppDataPath)" -Force -Confirm:$false | Out-Null
	}

	# Making new file to hold PID data, because it makes things easier for me
	#	and my noice self.
	New-Item -ItemType File -Path "$($ENV:hktPids)" -Force -Confirm:$false | Out-Null

	# Hiding the file.
	$hideFile = Get-Item "$($ENV:hktPids)" -Force
	$hideFile.Attributes = 'Hidden'

	# Add in the headers.
	Add-Content -Path "$($ENV:hktPids)" -Force -Confirm:$false -Value "PID, `"Process`""

} Else {
	# There is a file. Check if there are any processes logged and running.
	$pidData = Import-Csv -Path "$($ENV:hktPids)"

	# Is there any data there? That can happen if the computer lost power without
	#	notice, or some other reason, like a cleanup service.
	If ($pidData) {
		ForEach ($proc in $pidData.PID) {
			# See if there's a Process with this ID.
			$chkPid = Try {Get-Process -Id $proc -ErrorAction SilentlyContinue} Catch {$False}
			# If there is a process with this ID running, end it.
			If ($chkPid) { Stop-Process $proc -Force }
		}
		# Clears the file, for a new run.
		(Get-Content "$($ENV:hktPids)" -First 1) | Set-Content "$($ENV:hktPids)"
	}
}

# Okay, so, we're pretty well should be up and running now. Tell the processes
#	file.
Add-Content -Path "$($ENV:hktPids)" -Force -Confirm:$false -Value "`"$PID`",`"Parent`""