$OutputCollection = New-Object System.Collections.ArrayList
$OutputCollectionPath = 'C:\Programs\GetUsersFromAD\UserList.csv'

$OU = "OU=Maywood,DC=trinity-health,DC=org"


Import-Module ActiveDirectory

#$UserList = Get-ADGroupMember -Identity $OU -Recursive | Where-Object { $_.objectClass -eq 'user' } | Select-Object Name, SamAccountName
#Get-ADGroupMember -Identity 'xhpk6327' -Recursive | Where-Object { $_.objectClass -eq 'user' }
$UserList = Get-ADUser -Filter * -SearchBase $OU -Properties 'Name', 'SamAccountName', 'EmailAddress', 'Title', 'Department', 'Manager', 'Enabled'
#Get-ADUser -Filter * -SearchBase $OU -Properties *


FOREACH ($ListedUser in $UserList) {

    #Replace 'username' with the actual username (SamAccountName) or UserPrincipalName.
    #$TargetedUser = Get-ADUser -Identity $($ListedUser.SamAccountName) -Properties * | Select-Object 'EmailAddress', 'Title', 'Department', 'Manager', 'Enabled'
    #Get-ADUser -Identity 'xhpk6327' -Properties * | Out-File -FilePath 'C:\Programs\GetUsersFromAD\FredLinthicum.txt'

    $Target = [PSCustomObject]@{ 
        'FullName' = [string]$ListedUser.Name
        'UserName' = [string]$ListedUser.SamAccountName
        'EmailAddress' = [string]$ListedUser.EmailAddress
        'Title' = [string]$ListedUser.Title
        'Department' = [string]$ListedUser.Department
        'Manager' = [string]$(Get-ADUser -Identity $($ListedUser.Manager) -Properties 'Name').Name
        'Enabled' = [string]$ListedUser.Enabled
        'LockedOut' = [bool]$False
    } #End $Target

    $OutputCollection.Add($Target) | Out-Null

}

$OutputCollection | Export-Csv -Path $OutputCollectionPath -NoTypeInformation