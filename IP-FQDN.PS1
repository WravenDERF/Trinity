$FileContents = Get-Content -Path "C:\Users\xhpk6327\Downloads\targetList.log"
FOREACH ($Address in $FileContents) {
    TRY {
        #[System.Net.Dns]::GetHostByAddress($Address).Hostname
        [System.Net.Dns]::GetHostAddresses($Address).IPAddressToString
    } CATCH {
        #Write-Host -Object $('Could not find FQDN')
        Write-Host -Object $('Could not find IP')
    }
}
