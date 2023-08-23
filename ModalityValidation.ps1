FUNCTION Get-DCMTK {

    #Download and expand DCMTK.
    #Works with 3.6.6

    PARAM(
        [string]$WebAddress = 'https://dicom.offis.de/download/dcmtk/dcmtk366/bin/dcmtk-3.6.6-win64-dynamic.zip',
        [string]$OutFile = 'C:\Installs\DCMTK.zip',
        [string]$ExtractionFolder = 'C:\Programs\ModalityValidation'
    )

    IF (-NOT $(Test-Path -Path "$ExtractionFolder\dcmtk-3.6.6-win64-dynamic\bin\findscu.exe")) { 
        Invoke-RestMethod -Uri $WebAddress -OutFile $OutFile
        Expand-Archive -LiteralPath $OutFile -DestinationPath $ExtractionFolder
    } 
}




FUNCTION Get-CECHO {

    #Gets status of DICOM listener.

    PARAM(
        [string]$IP,
        [string]$AET,
        [string]$Port
    )

    $Command = "$CECHO --call $AET $IP $Port"
    $Reply = Invoke-Expression -Command $Command

    $Output = [bool]$False
    FOREACH ($ReturnedLine in $Reply) {
        IF ($ReturnedLine -eq 'I: Received Echo Response (Success)') {
            $Output = [bool]$true
        }#End IF
    } #End FOREACH

    RETURN $Output
    
}





Get-DCMTK
$CECHO = 'C:\Programs\ModalityValidation\dcmtk-3.6.6-win64-dynamic\bin\echoscu.exe -v'
#https://support.dcmtk.org/docs-361/echoscu.html
#$CECHO = 'C:\Programs\ModalityValidation\dcmtk-3.6.6-win64-dynamic\bin\echoscu.exe -v -to 1'

#Look at initial list of servers
$ListPath = 'C:\Programs\ModalityValidation\List.csv'
#$ListSource = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vQYi8CaFg6lPurVld6lIgsPFHb5DvEGBNVHP1vaPzAd5faOxmC8PC7InXAlxddABw7ZhH6o4E32rk-_/pub?gid=1202428146&single=true&output=csv'
#Invoke-RestMethod -Uri $ListSource -OutFile $ListPath
#$List = Import-Csv -Path $ListPath -Delimiter ','
#$MaxCount = (($List | Measure-Object).Count / 100)

#Save a list when done.
$ListOut = 'C:\Programs\ModalityValidation\List.csv'

#Identify if the script shood loop.
$Loop = [bool]$True
DO {

    #Clears the screen and sets parimeters.
    Clear-Host
    $Index = 0

    #Create collection for data.
    $DataCollection = New-Object System.Collections.ArrayList

    #Look at initial list of servers
    $List = Import-Csv -Path $ListPath -Delimiter ','
    $MaxCount = (($List | Measure-Object).Count / 100)

    FOREACH ($TargetModality in $List) {

        #This is a filter for the data.
        IF (0 -eq 0) {

            #Create an object to hold all data.
            $Target = [PSCustomObject]@{ 
                'Description' = [string]$TargetModality.Description
                'AET' = [string]$TargetModality.AET
                'IP' = [string]$TargetModality.IP
                'Port' = [string]$TargetModality.Port
                'Count' = [int]$TargetModality.Count
            } #End $Target

            $Index = $Index + 1
            IF (Get-CECHO -IP $Target.IP -AET $Target.AET -Port $Target.Port) {
                $Target.Count = [int]$TargetModality.Count + 1
            } #End IF

            #Display results.
            Write-Host -Object $Index -ForegroundColor 'Cyan'
            $Target

            #Add results to collection.
            $DataCollection.Add($Target) | Out-Null

        } #End IF ($TargetComputer.System -ne 'Workstation') {

    } #End FOREACH ($TargetPC in $Collection) { 

    #Beep and display final results.
    #Clear-Host
    #$DataCollection | Format-Table
    #$DataCollection | Export-Csv -Path $ListOut -NoTypeInformation -Append
    #Start-Sleep -Seconds 30
    #$DataCollection = New-Object System.Collections.ArrayList
    $DataCollection | Export-Csv -Path $ListOut -NoTypeInformation

} UNTIL ($Loop -eq $False) #End DO

#Create a spreadsheet out of the final results
#IF (Test-Path -Path $ListOut) {Remove-Item -Path $ListOut -Force}
#Stop-Process -Name 'EXCEL.EXE'
