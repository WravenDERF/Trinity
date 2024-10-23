#Check AD for AD Info
#Username: Trinity-Health\UTHDLifeImage
#Password: EeWiCdQJjJDyS0IkKV5

#C:\Programs\GetUsersFromAD\Systems - LifeImageUsers.csv

<#
$Credential = Get-Credential
$UserName = 'xhpk6327'
$UserName = 'rqlm5270'
$UserName = 'srafidia'
$Filter = "(&(objectClass=user)(samAccountName=$UserName))"
$Server = 'addir.trinity-health.org'
$OU = 'OU=Users,OU=Maywood,DC=trinity-health,DC=org'
$Searcher = New-Object DirectoryServices.DirectorySearcher
$Searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($Server):389/$OU", $Credential.UserName, $Credential.GetNetworkCredential().Password).SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($Server):389/$OU", $Credential.UserName, $Credential.GetNetworkCredential().Password)
$Searcher.SearchScope = 'Subtree'
$Searcher.Filter = $Filter
$Searcher.FindAll()
$Searcher
#>







#C:\Programs\GetUsersFromAD\Systems - LifeImageUsers.csv

# Import the Active Directory module (only necessary if it's not already loaded)
Import-Module ActiveDirectory

#Get the list for output.
$UserListPath = 'C:\Programs\GetUsersFromAD\Systems - LifeImageUsers.csv'
$UserList = Import-Csv -Path $UserListPath -Delimiter ','
#$UserList = 'xhpk6327'
$OutputCollection = New-Object System.Collections.ArrayList

# Function to get the Manager for a single user
function Get-ADUserManager {
    param (
        [string]$username  # Accepts the username (sAMAccountName) as input
    )

    # Retrieve the user from Active Directory
    $user = Get-ADUser -Identity $username -Properties Manager
        $user = Get-ADUser -Identity $username -Properties Enabled

    # If the Manager property is populated, retrieve and display the Manager's information
    if ($user.Manager) {
        $manager = Get-ADUser -Identity $user.Manager
        Write-Output "User: $username | Manager: $($manager.Name)"
    }
    else {
        Write-Output "User: $username has no manager listed."
    }
}

# Example: Retrieve the manager for a single user (replace 'jdoe' with the actual username)
# Get-ADUserManager -username 'xhpk6327'

# Example: Retrieve the manager for multiple users

foreach ($Target in $UserList) {

    $Target.username

    $User = [PSCustomObject]@{
        'PullDate' = [string]$Target.PullDate

        'ActiveAccount' = [bool]$False
        'Manager' = [string]$Null
        'JobTitle' = [string]$Null

        'username' = [string]$Target.username
        'family_name' = [string]$Target.family_name
        'suffix' = [string]$Target.suffix
        'given_name' = [string]$Target.given_name
        'profession' = [string]$Target.profession
        'email_address' = [string]$Target.email_address
        'domain' = [string]$Target.domain
        'ROLE' = [string]$Target.ROLE
        'GROUPS' = [string]$Target.GROUPS
        'SPECIALTY' = [string]$Target.SPECIALTY
        'latest_login_date' = [string]$Target.latest_login_date
    }

    # Retrieve the user from Active Directory
    $AD = Get-ADUser -Identity $Target.username -Properties 'Manager' , 'Enabled' , 'Title'
    $User.ActiveAccount = $AD.Enabled
    $User.Manager = $(Get-ADUser -Identity $($AD.Manager) -Properties 'Name').Name
    $User.JobTitle = $AD.Title

    $User

    $OutputCollection.Add($User) | Out-Null


}

$OutputCollectionPath = 'C:\Programs\GetUsersFromAD\UserList.csv'
$OutputCollection | Export-Csv -Path $OutputCollectionPath -NoTypeInformation
