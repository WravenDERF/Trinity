$Date = Get-Date
$Activity = $Null
$DayofWeek = $Null
$Month = $Null
$EnvironmentNumber = $Null

$Environments = @(
    '6253',
    '6254',
    '6255'
)

$OutputLogfile = {
    
    [bool]$SuccessfulResult = $False

    FOREACH ($Line in $Results) {
        IF (($Line -eq '  Daily Backup completed successfully.') -or ($Line -eq '  Monthly Backup completed successfully.')) {
            [bool]$SuccessfulResult = $True
        } 
    }

    IF ($SuccessfulResult) {
        $Dataline = "$(Get-Date -Format 'yyyyMMdd-HH:mm') | Database$EnvironmentNumber successfully did a $Activity backup." | Out-File -FilePath 'C:\Logs\BioDoseBackup.log' -Append
    } ELSE {
        $Dataline = "$(Get-Date -Format 'yyyyMMdd-HH:mm') | Database$EnvironmentNumber failed to do a $Activity backup." | Out-File -FilePath 'C:\Logs\BioDoseBackup.log' -Append
    }

}

SWITCH ($Date.Month) {
    '1' {$Month = '01-January'}
    '2' {$Month = '02-February'}
    '3' {$Month = '03-March'}
    '4' {$Month = '04-April'}
    '5' {$Month = '05-May'}
    '6' {$Month = '06-June'}
    '7' {$Month = '07-July'}
    '8' {$Month = '08-August'}
    '9' {$Month = '09-September'}
    '10' {$Month = '10-October'}
    '11' {$Month = '11-November'}
    '12' {$Month = '12-December'}
}

SWITCH ($Date.DayOfWeek) {
    'Sunday' {$DayofWeek = '1-Sunday'}
    'Monday' {$DayofWeek = '2-Monday'}
    'Tuesday' {$DayofWeek = '3-Tuesday'}
    'Wednesday' {$DayofWeek = '4-Wednesday'}
    'Thursday' {$DayofWeek = '5-Thursday'}
    'Friday' {$DayofWeek = '6-Friday'}
    'Saturday' {$DayofWeek = '7-Saturday'}
}

FOREACH ($ServerNumber in $Environments) {
    
    $EnvironmentNumber = $ServerNumber

    IF ($Date.Day -eq 1) {
        $Activity = 'Monthly'
        $Command = "E:\NUCM00$ServerNumber\NUCMSQL\backup.exe -p7758 -n -m -b""E:\NUCM00$ServerNumber\databackup$ServerNumber\Monthly\$Month"""
        $Command
        $Results = Invoke-Expression -Command $Command
        Invoke-Command -ScriptBlock $OutputLogfile
    }

    $Activity = 'Daily'
    $Command = "E:\NUCM00$ServerNumber\NUCMSQL\backup.exe -p7758 -n -b""E:\NUCM00$ServerNumber\databackup$ServerNumber\Daily\$DayofWeek"""
    $Command
    $Results = Invoke-Expression -Command $Command
    Invoke-Command -ScriptBlock $OutputLogfile
}
