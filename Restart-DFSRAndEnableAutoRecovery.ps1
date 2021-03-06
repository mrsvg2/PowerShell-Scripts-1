####################################################
#
# Title: Restart-DFSRAndEnableAutoRecovery
# Date Created : 2017-12-28
# Last Edit: 2017-12-29
# Author : Andrew Ellis
# GitHub: https://github.com/AndrewEllis93/PowerShell-Scripts
#
# Nice and short and simple. It restarts the DFSR service on all domain controllers (I schedule this to run nightly. This isn't really necessary but I have found it to prevent some misc issues that crop up once in a blue moon) and enables DFSR auto-recovery, which for whatever reason is disabled on domain controllers by default.
#
####################################################

Function Restart-DFSRAndEnableAutoRecovery {
    <#
    .SYNOPSIS
    Gets all DCs, restarts the DFSR service, and enables DFSR auto recovery, which is turned off by default for who knows what reason. 
    
    .DESCRIPTION
    
    .EXAMPLE
    Restart-DFSRAndEnableAutoRecovery
    
    .LINK
    https://github.com/AndrewEllis93/PowerShell-Scripts

    .NOTES
    Author: Andrew Ellis
    #>

    Write-Output "Getting list of DCs..."
    $DCs = Get-ADGroupMember 'Domain Controllers' -ErrorAction Stop

    ForEach ($DC in $DCs)
    {
        $Output = "Restarting DFSR service on " + $DC.Name + "..."
        Write-Output $Output
        Invoke-Command -ComputerName $DC.Name -ScriptBlock {Restart-Service DFSR}
        Start-Sleep 5
        Write-Output ("Enabling DFSR auto recovery on " + $DC.Name + "...")
        Invoke-Command -ComputerName $DC.Name -ScriptBlock {cmd.exe /c wmic /namespace:\\root\microsoftdfs path dfsrmachineconfig set StopReplicationOnAutoRecovery=FALSE}
    }
}
Function Start-Logging {
    <#
    .SYNOPSIS
    This function starts a transcript in the specified directory and cleans up any files older than the specified number of days. 

    .DESCRIPTION
    Please ensure that the log directory specified is empty, as this function will clean that folder.

    .EXAMPLE
    Start-Logging -LogDirectory "C:\ScriptLogs\LogFolder" -LogName $LogName -LogRetentionDays 30

    .LINK
    https://github.com/AndrewEllis93/PowerShell-Scripts

    .NOTES
    Author: Andrew Ellis
    #>
    Param (
        [Parameter(Mandatory=$true)]
        [String]$LogDirectory,
        [Parameter(Mandatory=$true)]
        [String]$LogName,
        [Parameter(Mandatory=$true)]
        [Int]$LogRetentionDays
    )

   #Sets screen buffer from 120 width to 500 width. This stops truncation in the log.
   $ErrorActionPreference = 'SilentlyContinue'
   $pshost = Get-Host
   $pswindow = $pshost.UI.RawUI

   $newsize = $pswindow.BufferSize
   $newsize.Height = 3000
   $newsize.Width = 500
   $pswindow.BufferSize = $newsize

   $newsize = $pswindow.WindowSize
   $newsize.Height = 50
   $newsize.Width = 500
   $pswindow.WindowSize = $newsize
   $ErrorActionPreference = 'Continue'

   #Remove the trailing slash if present. 
   If ($LogDirectory -like "*\") {
       $LogDirectory = $LogDirectory.SubString(0,($LogDirectory.Length-1))
   }

   #Create log directory if it does not exist already
   If (!(Test-Path $LogDirectory)) {
       New-Item -ItemType Directory $LogDirectory -Force | Out-Null
   }

   $Today = Get-Date -Format M-d-y
   Start-Transcript -Append -Path ($LogDirectory + "\" + $LogName + "." + $Today + ".log") | Out-Null

   #Shows proper date in log.
   Write-Output ("Start time: " + (Get-Date))

   #Purges log files older than X days
   $RetentionDate = (Get-Date).AddDays(-$LogRetentionDays)
   Get-ChildItem -Path $LogDirectory -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $RetentionDate -and $_.Name -like "*.log"} | Remove-Item -Force
} 

#Start logging.
Start-Logging -logdirectory "C:\ScriptLogs\Restart-DFSRAndEnableAutoRecovery" -logname "Restart-DFSRAndEnableAutoRecovery" -LogRetentionDays 30

#Start function.
Restart-DFSRAndEnableAutoRecovery

#Stops logging.
Stop-Transcript
