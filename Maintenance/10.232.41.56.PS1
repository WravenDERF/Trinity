#Set up Windows Remote Managment
	#Enable-PSRemoting -Force
	#Set-Item wsman:\localhost\client\trustedhosts * -Force
	#Restart-Service WinRM


#adminpros
Invoke-Command -ComputerName 'mwpacsfujiapp.luhsads.luhs.org' -Credential 'luhsads\prosadmin' -ScriptBlock {$(Get-Service -Name 'ProsolvMWLService').Status}

Invoke-Command -ComputerName 'mwpacsfujiapp.luhsads.luhs.org' -Credential 'luhsads\prosadmin' -ScriptBlock {$(Get-Service -Name 'WinRM').Status}
Invoke-Command -ComputerName 'mwpacsfujiapp.luhsads.luhs.org' -Credential 'luhsads\prosadmin' -ScriptBlock {Stop-Service -Name 'WinRM'}





$(Get-Service -Name 'ProsolvMWLService').Status


Restart-Service -Name winm
