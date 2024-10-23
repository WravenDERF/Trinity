$GroupName = "UTHD E Unity Boise Users AP U"

$OutputCollection = New-Object System.Collections.ArrayList
$OutputCollectionPath = 'C:\Programs\GetUsersFromAD\UserList.csv'






Import-Module ActiveDirectory

$UserList = Get-ADGroupMember -Identity $GroupName -Recursive | Where-Object { $_.objectClass -eq 'user' } | Select-Object Name, SamAccountName

FOREACH ($ListedUser in $UserList) {

    # Replace 'username' with the actual username (SamAccountName) or UserPrincipalName.
    $TargetedUser = Get-ADUser -Identity $($ListedUser.SamAccountName) -Properties * | Select-Object 'EmailAddress', 'Title', 'Department', 'Manager', 'Enabled'
    Get-ADUser -Identity 'xhpk6327' -Properties * | Out-File -FilePath 'C:\Programs\GetUsersFromAD\FredLinthicum.txt'

    $Target = [PSCustomObject]@{ 
        'FullName' = [string]$ListedUser.Name
        'UserName' = [string]$ListedUser.SamAccountName
        'EmailAddress' = [string]$TargetedUser.EmailAddress
        'Title' = [string]$TargetedUser.Title
        'Department' = [string]$TargetedUser.Department
        'Manager' = [string]$(Get-ADUser -Identity $($TargetedUser.Manager) -Properties 'Name').Name
        'Enabled' = [string]$TargetedUser.Enabled
        'LockedOut' = [bool]$False
    } #End $Target

    $Target

    $OutputCollection.Add($Target) | Out-Null

}

$OutputCollection | Export-Csv -Path $OutputCollectionPath -NoTypeInformation