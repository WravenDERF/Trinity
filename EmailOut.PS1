    #To = 'Bob Grant <bob.grant@luhs.org>'
    #To = 'Loyola Informatics Team <LUHSImagingInformaticsAlerts@lumc.edu>'
    #To = 'Fred Linthicum <fred.linthicum@trinity-health.org>'


#Phrase that causes us concern.
$FullLineOutput = 'Query Complete:  Status - Internal Error.  200 responses received.'

#This is the mail message.
$MailMessage = @{
    From = 'Laurel Bridge Compass 227 <compass227@trinity-health.org>'
    To = 'Loyola Informatics Team <LUHSImagingInformaticsAlerts@lumc.edu>'
    Subject = 'Test: Worklist Error'
    SmtpServer = 'smtp.trinity-health.org'
    Body = 'Please check CCG worklist functionality. This is a test by Fred and Bob.'
    Priority = 'High'    
}


#The path to the file to read.
$FilePath = 'C:\temp\hologic_dmwl.out'

# This reads the contents of a text file and stores it in a variable
$FileContent = Get-Content -Path $FilePath

#Standard boolean is set to false which will send an email if not found.
$LineExist = $False

#Loop through every line in the file.
FOREACH ($Line in $FileContent) {

    #If the line matches what we are looking for, do something.
    IF ($Line -eq $FullLineOutput) {
        
        #If the line exist, it changes the falue to true, and the email will not be sent.
        $LineExist = $True
        Write-Host -Object $('I found the line.')

    }
    
}



#This will only email if we did not find the line.
IF ($LineExist -eq $False) {

    #This will email out.
    Send-MailMessage @MailMessage

}
