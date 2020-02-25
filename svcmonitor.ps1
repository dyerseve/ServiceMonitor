<#Set-ExecutionPolicy Unrestricted
# Set services to monitor and restart

#>
#Variables
$Services = @("dhcp","dns","spooler")
#Functions
#checks if powershell is in Administrator mode, if not powershell will fix it  
Function Run-AsAdmin
{
	if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {     
		$arguments = "& '" + $myinvocation.mycommand.definition + "'"  
		Start-Process powershell -Verb runAs -ArgumentList $arguments  
		Break  
	}
}  

##Pause Function
Function Pause($M="Press any key to continue . . . "){If($psISE){$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);Return};Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;While($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host}

## File Dialog Prompt (title doesn't seem to work)
Function Get-FileName($initialDirectory, $diagTitle)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
	$OpenFileDialog.Title = $diagTitle
}

#Debugging
$DebugPreference = "Continue"

#Logging feature
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
#current script directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#current script name
$path = Get-Location
$scriptName = $MyInvocation.MyCommand.Name
$scriptLog = "$scriptPath\log\$scriptName.log"
#start a transcript file
Start-Transcript -path $scriptLog

Foreach ($Service in $Services)
		{
		
			#Verify that service exist on server
			If (Get-Service -Name $Service -ErrorAction SilentlyContinue)
				{                                                            
					Write-Output "Checking Status of $Service..."
				
					#Get server service status
					$SRVCArr = Get-Service -Name $Services -ErrorAction SilentlyContinue
					$SRVC = $SRVCArr | ForEach-Object {
					New-Object PSObject -Property @{
					'Service Name'= $_.Name
					'Service Status'= $_.Status
													}
												}
					#If service is not running, start the service, and add to counter
					If ($SRVC.'Service Status' -ne "Running")
						{
							Get-Service -Name $Service | Set-Service -Status Running
						
							#Create new array for services that needed to be restarted
							$SRVCRS = New-Object psobject
							$SRVCRS | Add-Member -MemberType NoteProperty -Name "Service" -Value "$Service"
							$SVEMSV = $SRVCRS.Service
						}
				
					#If service is running, display status
					If ($SRVC.'Service Status' -eq "Running")
						{
							Write-Output "$Service Service is already started"
							"`n"
						}
				}
					
			#If the services does not exist on the server, display result
			Else {"$Service does not exist"}
			}

########Always place these EOF########
#Close all open sessions
try
{
	Remove-PSSession $Session
}
catch
{
   #Just suppressing Error Dialogs
}

Get-PSSession | Remove-PSSession
#Close Transcript log
Stop-Transcript