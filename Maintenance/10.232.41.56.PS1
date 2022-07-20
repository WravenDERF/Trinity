#[Admin] Create Scheduled Task on local computer. 
    $ScheduledTask = {
        $Actions = New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument '-ExecutionPolicy RemoteSigned -Command "& {Invoke-Expression $($(Invoke-WebRequest 'https://raw.githubusercontent.com/WravenDERF/Trinity/main/Maintenance/10.232.41.56.PS1' -UseBasicParsing).Content)}'
        $Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 2 -DaysOfWeek 'Sunday' -At '4am'
        $Principal = New-ScheduledTaskPrincipal -UserId 'LOCALSERVICE' -RunLevel 'Highest' -LogonType 'ServiceAccount'
        $Settings = New-ScheduledTaskSettingsSet
        $Task = New-ScheduledTask -Action $Actions -Principal $Principal -Trigger $Trigger -Settings $Settings
        Register-ScheduledTask 'LUHS\FredTest' -InputObject $Task
    }
    #Invoke-Command -ScriptBlock $ScheduledTask

#Main
    $Computer = 'mwpacsfujiapp.luhsads.luhs.org'
    $Username = 'luhsads\prosadmin'
    $Password = ConvertTo-SecureString 'adminpros' -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($Username, $Password)
    Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock {
        $(Get-Service -Name 'ProsolvMWLService').Status #Get initial status.
        Stop-Service -Name 'ProsolvMWLService' #Stop Service
        $(Get-Service -Name 'ProsolvMWLService').Status #Display stopped service
        Start-Sleep -Seconds 60 #Wait 60 seconds before starting the service.
        Start-Service -Name 'ProsolvMWLService' #Start the service.
        $(Get-Service -Name 'ProsolvMWLService').Status #Verify the service is running.
    }
