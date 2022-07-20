#Credentials
    $Computer = 'mwpacsfujiapp.luhsads.luhs.org'
    $Username = 'luhsads\prosadmin'
    $Password = ConvertTo-SecureString 'adminpros' -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($Username, $Password)
    Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock {$(Get-Service -Name 'ProsolvMWLService').Status}

#Stop Service
    Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock {
        Stop-Service -Name 'ProsolvMWLService'
        $(Get-Service -Name 'ProsolvMWLService').Status
    }

#Wait to Restart
    Start-Sleep -Seconds 60

#Start Service
    Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock {
        Start-Service -Name 'ProsolvMWLService'
        $(Get-Service -Name 'ProsolvMWLService').Status
    }
