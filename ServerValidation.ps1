#Set debug mode.
$Debug = [bool]$False

#Set Loop Mode
$Loop = [bool]$True

#Define path for csv in.
$ListPath = 'C:\Programs\ServerValidation\Servers.csv'

#Define path for source CSV.
Invoke-RestMethod -Uri 'https://docs.google.com/spreadsheets/d/e/2PACX-1vQYi8CaFg6lPurVld6lIgsPFHb5DvEGBNVHP1vaPzAd5faOxmC8PC7InXAlxddABw7ZhH6o4E32rk-_/pub?gid=140352933&single=true&output=csv' -OutFile $ListPath

#Define path for csv out.
$ListOut = 'C:\Installs\ServerValidation.csv'

#Create collection for data.
$DataCollection = New-Object System.Collections.ArrayList

#Download and expand DCMTK.
IF (-NOT $(Test-Path -Path 'C:\Programs\dcmtk-3.6.6-win64-dynamic\bin\findscu.exe')) { 
    Invoke-RestMethod -Uri 'https://dicom.offis.de/download/dcmtk/dcmtk366/bin/dcmtk-3.6.6-win64-dynamic.zip' -OutFile 'C:\Installs\DCMTK.zip'
    Expand-Archive -LiteralPath 'C:\Installs\DCMTK.zip' -DestinationPath 'C:\Programs'
} #End IF (-NOT $(Test-Path -Path 'C:\Programs\dcmtk-3.6.6-win64-dynamic\bin\findscu.exe'))
$CECHO = 'C:\Programs\dcmtk-3.6.6-win64-dynamic\bin\echoscu.exe -v'

#Looks through the list and retreives data for each line item.
Clear-Host
Invoke-RestMethod -Uri $WebPath -OutFile $ListPath
$List = Import-Csv -Path $ListPath -Delimiter ','
$MaxCount = (($List | Measure-Object).Count / 100)
$Index = 0
FOREACH ($TargetComputer in $List) {

    #Progress bar keeps track of how long it takes.
    $Index = $Index + 1
    $Progress = [math]::Round(($Index / $MaxCount), 4)
    Write-Progress -Activity "Progress" -Status "$Progress% Complete" -PercentComplete $Progress

    #Create an object to hold all data.
    $Target = [PSCustomObject]@{ 
        'System' = [string]$TargetComputer.System
        'Environment' = [string]$TargetComputer.Environment
        'Role' = [string]$TargetComputer.Role
        'IP' = [string]$TargetComputer.IP
        'FQDN' = [string]$Null
        'RebootOrder' = [string]$TargetComputer.RebootOrder
        'Status' = [string]$False
        'Action' = [string]$TargetComputer.Action
        'ObjectName' = [string]$TargetComputer.ObjectName
        'Result' = [string]$Null
    } #End $Target

    #Gets the FQDN of the IP address
    $ResolveIPtoFQDN = {
        PARAM ([string]$IP)
        $Target.FQDN = [System.Net.Dns]::GetHostByAddress($IP).Hostname
    } #End $ResolveIPtoFQDN
    Invoke-Command -ScriptBlock $ResolveIPtoFQDN -ArgumentList $Target.IP

    #Pings the target to see if it is up.
    $Target.Status = Test-Connection -Computer $Target.FQDN -Count 1 -Quiet

    #Gets the last boot info from WMI and returns it as a readable date and time.
    $ResolveOSLastBoot = {
        PARAM ([string]$FQDN, [string]$RebootOrder)
        $Win32_OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $FQDN
        $Result = [string]$([System.Management.ManagementDateTimeConverter]::ToDateTime($Win32_OperatingSystem.LastBootUpTime))
        $Target.Result = "$Result [$RebootOrder]"
    } #End $ResolveOSLastBoot

    #Gets the status of specified service on remote workstation.
    $ResolveServiceStatus = {
        PARAM ([string]$FQDN, [string]$ServiceName)
        $Result = $(Get-Service -ComputerName $FQDN -Name $ServiceName).Status
        SWITCH ($Result) {
            'Running' {$Target.Result = $Result}
            'Stopped' {
                Get-Service -ComputerName $FQDN -Name $ServiceName | Restart-Service -Force
                $Target.Result = 'Restarted by Script'
            }
        } #End SWITCH ($Result)
    } #End $ResolveServiceStatus

    #Gets status of DICOM listener.
    $ResolveCECHO = {
        PARAM ([string]$IP, [string]$AET, [string]$Port)
        $Command = "$CECHO --call $AET $IP $Port"
        $Reply = Invoke-Expression -Command $Command
        $Target.Result = [bool]$False
        FOREACH ($ReturnedLine in $Reply) {
            IF ($ReturnedLine -eq 'I: Received Echo Response (Success)') {
                $Target.Result = [bool]$True
            } #End IF ($ReturnedLine -eq 'I: Received Echo Response (Success)')
        } #End FOREACH ($ReturnedLine in $Reply)
    } #End $ResolveCECHO

    $ResolveWebLink = {
        PARAM ([string]$WebAddress)
        $HTTP_Request = [System.Net.WebRequest]::Create($WebAddress)
        $HTTP_Response = $HTTP_Request.GetResponse()
        $Target.Result = $HTTP_Response.StatusCode
    } #End $ResolveWebLink

    #Get Task info
    $ResolveTaskStatus = {
        PARAM ([string]$FQDN, [string]$TaskName)
        $Connection = New-CimSession -ComputerName $FQDN
        $Result = Get-ScheduledTaskInfo -TaskName $TaskName -CimSession $Connection
        IF ($Result.LastTaskResult -eq 0) {
            $Target.Result = "Successful $($Result.LastRunTime)"
        } ELSE {
            $Target.Result = "Failed $($Result.LastRunTime)"
        } #End IF ($Result.LastTaskResult -eq 0)
    } #End $ResolveTaskStatus

    #Check if port is open
    $CheckPortStatus = {
        PARAM ([string]$FQDN, [string]$PortNumber)
        $Target.Result = $(Test-NetConnection -ComputerName $FQDN -Port $PortNumber).TcpTestSucceeded
    } #End $CheckPortStatus

    #Logic Switch Statement to look at items
    IF ($Target.Status) {
        SWITCH ($Target.Action) {
            'Get-OSInfo' {Invoke-Command -ScriptBlock $ResolveOSLastBoot -ArgumentList $Target.FQDN, $Target.RebootOrder}
            'Get-ServiceStatus' {Invoke-Command -ScriptBlock $ResolveServiceStatus -ArgumentList $Target.FQDN, $Target.ObjectName}
            'Test-CECHO' {Invoke-Command -ScriptBlock $ResolveCECHO -ArgumentList $Target.IP, $($Target.ObjectName).Split('[')[0], $($Target.ObjectName).Split('[]')[1]}
            #'Get-WebLink' {Invoke-Command -ScriptBlock $ResolveWebLink -ArgumentList $Target.ObjectName}
            'Get-TaskStatus' {Invoke-Command -ScriptBlock $ResolveTaskStatus -ArgumentList $Target.FQDN, $Target.ObjectName}
            'Check-Port' {Invoke-Command -ScriptBlock $CheckPortStatus -ArgumentList $Target.FQDN, $Target.ObjectName}
        } #End SWITCH ($Target.Action)
    } #End IF ($Target.Status)

    #Display results.
    Write-Progress -Activity "Progress" -Status "$Progress% Complete" -PercentComplete $Progress -Completed
    IF ($Debug) {$Target}

    #Add results to collection.
    $DataCollection.Add($Target) | Out-Null 

} #End FOREACH ($TargetPC in $Collection) { 

#Beep and display final results.
[console]::beep(1000,500)
$DataCollection | Format-Table

#Create a spreadsheet out of the final results
#IF (Test-Path -Path $ListOut) {Remove-Item -Path $ListOut -Force}
#Stop-Process -Name 'EXCEL.EXE'
$DataCollection | Export-Csv -Path $ListOut -NoTypeInformation

IF ($Loop) {

    DO {

        FOREACH ($TargetComputer in $List) {

            #Create an object to hold all data.
            $Target = [PSCustomObject]@{ 
                'System' = [string]$TargetComputer.System
                'Environment' = [string]$TargetComputer.Environment
                'Role' = [string]$TargetComputer.Role
                'IP' = [string]$TargetComputer.IP
                'FQDN' = [string]$Null
                'RebootOrder' = [string]$TargetComputer.RebootOrder
                'Status' = [string]$False
                'Action' = [string]$TargetComputer.Action
                'ObjectName' = [string]$TargetComputer.ObjectName
                'Result' = [string]$Null
            } #End $Target

            #Gets the FQDN of the IP address
            $ResolveIPtoFQDN = {
                PARAM ([string]$IP)
                $Target.FQDN = [System.Net.Dns]::GetHostByAddress($IP).Hostname
            } #End $ResolveIPtoFQDN
            Invoke-Command -ScriptBlock $ResolveIPtoFQDN -ArgumentList $Target.IP

            #Pings the target to see if it is up.
            $Target.Status = Test-Connection -Computer $Target.FQDN -Count 1 -Quiet

            #Gets the last boot info from WMI and returns it as a readable date and time.
            $ResolveOSLastBoot = {
                PARAM ([string]$FQDN, [string]$RebootOrder)
                $Win32_OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $FQDN
                $Result = [string]$([System.Management.ManagementDateTimeConverter]::ToDateTime($Win32_OperatingSystem.LastBootUpTime))
                $Target.Result = "$Result [$RebootOrder]"
            } #End $ResolveOSLastBoot

            #Logic Switch Statement to look at items
            IF ($Target.Status) {
                SWITCH ($Target.Action) {
                    'Get-OSInfo' {Invoke-Command -ScriptBlock $ResolveOSLastBoot -ArgumentList $Target.FQDN, $Target.RebootOrder}
                    'Get-ServiceStatus' {Invoke-Command -ScriptBlock $ResolveServiceStatus -ArgumentList $Target.FQDN, $Target.ObjectName}
                    'Test-CECHO' {Invoke-Command -ScriptBlock $ResolveCECHO -ArgumentList $Target.IP, $($Target.ObjectName).Split('[')[0], $($Target.ObjectName).Split('[]')[1]}
                    #'Get-WebLink' {Invoke-Command -ScriptBlock $ResolveWebLink -ArgumentList $Target.ObjectName}
                    'Get-TaskStatus' {Invoke-Command -ScriptBlock $ResolveTaskStatus -ArgumentList $Target.FQDN, $Target.ObjectName}
                    'Check-Port' {Invoke-Command -ScriptBlock $CheckPortStatus -ArgumentList $Target.FQDN, $Target.ObjectName}
                } #End SWITCH ($Target.Action)
            } #End IF ($Target.Status)

            #Add results to collection.
            $DataCollection.Add($Target) | Out-Null 

        }

        #Display results
        Clear-Host
        $DataCollection | Format-Table
        $DataCollection = New-Object System.Collections.ArrayList
        Start-Sleep -Seconds 5

    } UNTIL (0 -eq 1) #End DO

}
