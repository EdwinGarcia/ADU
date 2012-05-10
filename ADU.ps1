# 
#.SYNOPSIS 
#    This script starts the HP Array Diagnostic Utility (ADU) and then gives it the command to generate a report, save it to the root of the current drive in XML format, then parse it to output a list of drives that could be having issues.
#.NOTES 
#    Additional Notes, eg 
#    File Name  : adu.ps1 
#    Author     : Edwin Garcia - v-edgar@microsoft.com or edwing@gmail.com
#    Requires   : PowerShell, PSExec
#.LINK 
#   http://wp.me/pKz4C-FR
#.EXAMPLE 
#    PS C:\> .\adu.ps1
#.LICENSE
#	ADU.PS1 by Edwin Garcia is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License. Permissions beyond the scope of this license may be available at http://therealedwin.com/contact/.
#
 
#We start by running the Test-Path cmdlet against the intsall folder for x64. If Test-Path returns True, meaning the x64 folder exists, we then move on to generate the report. If it doesn't exist, the else statement will launch the x86 location.
if (Test-Path "C:\Program Files (x86)\Compaq\Hpacucli\Bin\hpacucli.exe")
{
	PSExec /accepteula  "C:\Program Files (x86)\Compaq\Hpacucli\Bin\hpacucli.exe" ctrl all diag file=c:\temp\adureport.xml xml=on
}
else
{
	PSExec /accepteula  "C:\Program Files\Compaq\Hpacucli\Bin\hpacucli.exe" ctrl all diag file=c:\temp\adureport.xml xml=on
}

#As Powershell does not have a native way to put text into the clipboard, I had to pipe it directly to the clipboard program which can take input. You can see this implemented as the very last command.
new-alias  Out-Clipboard $env:SystemRoot\system32\clip.exe

#Formats the ADUreport.xml into a readable list.
$xml = [xml](Get-Content 'c:\temp\adureport.xml')
@($xml.SelectNodes('//Device[@deviceType = "PhysicalDrive"]', $null)) | %{
    $object = "" | Select-Object Location,Model,Serial,Firmware,ReadErrorsHard,ReallocatedSectors
    $object.Location = $_.marketingName -replace 'Physical Drive ',''
    $object.Model = (($_.SelectSingleNode('.//MetaProperty[@id = "Drive Model"]', $null)).value).Trim() -replace "\s *", " "
    $object.Serial = (($_.SelectSingleNode('.//MetaProperty[@id = "Drive Serial Number"]', $null)).value).Trim()
    $object.Firmware = (($_.SelectSingleNode('.//MetaProperty[@id = "Drive Firmware Revision"]', $null)).value).Trim()
    $object.ReadErrorsHard = [int] ($_.SelectSingleNode('.//MetaProperty[@id = "Read Errors Hard"]', $null)).value
    $object.ReallocatedSectors = [int] ($_.SelectSingleNode('.//MetaProperty[@id = "Reallocated Sectors"]', $null)).value
    Write-Output $object
} | Format-Table -AutoSize | Tee-Object -filepath c:\temp\aduoutput.txt | Out-Clipboard

#clear
Write-Output "Report copied to clipboard and saved to file."

#Asks the user if they want to open the report.
$input = read-host "Do you want to open the report? Y or N"

if ( $input -eq "y")
{
	psexec notepad c:\temp\aduoutput.txt
}
break