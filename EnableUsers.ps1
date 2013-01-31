##======================================================================================
##Script:  EnableLyncUsers.ps1
##Author:  Josh Reichardt
##Email:   jreichardt@gmrc.com
##Date:    10/9/12
##Purpose: Use this script to add users already in AD domain into Lync 2010 environment.
##Notes:   Reads in a CSV file with pre populated AD Display names.  Can be adjusted to
##  	   work with alternate AD names (eg SIP address, UPN or AD log on name).
##======================================================================================

#Variables.
$File = "C:\Lync\test.csv"
$Log = New-Item -ItemType File -Path "C:\Lync\userlog.txt" -Force

#Import CSV File
$UserArray = Import-CSV -Path $File

#Check if user file is empty.
if ($UserArray -eq $null)
{
	 write-host "No Users Found in Input File"
	 exit 0
}

#Get total number of users in CSV file and begin proccessing.
$count = $UserArray | Measure-Object | Select-Object -expand count
Write-Host "Found " $count "Users to import."
Write-Host "Processing Users.....`n"
$index = 1

ForEach ($User in $UserArray) {
	
	Write-Host "Processing User " $index " of " $count
	$Fullname = $User.DisplayName
	$aduser = get-csaduser -Identity $Fullname
	
	#Check if user is in AD.  Log if they are NOT.
	if ($aduser -eq $null) {
		$notinad = $true
		Write-Host "User " $Fullname " is not in AD.  Double check spelling, etc." -Foregroundcolor Red
		Add-Content -Path $Log -Value "$($Fullname) is not in AD.  Double check spelling, etc."
	}
	
	else {
		$notinad = $false
	}
	
	#If user is in AD check if enabled in Lync and log if enabled.
	if ($aduser.Enabled) {
		Write-Host $User.DisplayName "is already enabled in Lync, skipping."  -Foregroundcolor Yellow
		Add-Content -Path $Log -Value "$($Fullname) is already enabled in Lync."
	}		

	#User not enabled.
	else {
		Write-Host "Adding user " $User.DisplayName -Foregroundcolor Green
		Enable-CsUser -Identity $User.DisplayName -Registrarpool "lyncpoolGMRC.gmrcnt.local" -SipAddressType Emailaddress
	
		#Check if last command failed.  If it does, log it.
		if(!$?) {
			Add-Content -Path $Log -Value "$($Fullname) not enabled.  $(Get-Date)$($error[0])"
			continue
		}
		
	}

	$index++	
	
}
