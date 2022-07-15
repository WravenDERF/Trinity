#Not done yet. Had to stop for the day and saved this here. The idea being to have this run on the 10.232.41.162 server on a weekly basis and pull license files.

$Path = "\\MW031107PC02.luhsads.luhs.org\c$\Program Files (x86)\Pacsgear\PacsSCAN\config\license.xml"
$XPath = "//KEY"
Select-Xml -Path $Path -XPath $Xpath | foreach {$_.node.InnerXML}

https://raw.githubusercontent.com/WravenDERF/Trinity/main/PascScan-2022.07.15.log

Invoke-Expression $($(Invoke-WebRequest 'https://raw.githubusercontent.com/WravenDERF/Trinity/main/PascScan-2022.07.15.log' -UseBasicParsing).Content)
$(Invoke-WebRequest 'https://raw.githubusercontent.com/WravenDERF/Trinity/main/PascScan-2022.07.15.log' -UseBasicParsing).Content


$Index = 0
$ListPath = 'D:\Fred-PacsScan\List.Log'
Invoke-WebRequest -URI 'https://raw.githubusercontent.com/WravenDERF/Trinity/main/PascScan-2022.07.15.log' -OutFile $ListPath
$Workbook = Get-Content -Path $ListPath

$Computer = [PSCustomObject]@{
    'Index' = [string]$Null
    'Hostname' = [string]$Null
    'Key' = [string]$Null
    'ID' = [string]$Null
}

FOREACH ($Row in $Workbook) {
    $Computer.Index = $Index
    $Computer.Hostname = $Row

    IF (Test-Connection -ComputerName $Row -Count 1 -Quiet) {
        $PathXML = "\\$Row\c$\Program Files (x86)\Pacsgear\PacsSCAN\config\license.xml"

        $XPath = "//KEY"
        $Computer.Key = Select-Xml -Path $Path -XPath $Xpath | FOREACH {$_.node.InnerXML}

        $XPath = "//ID"
        $Computer.ID = Select-Xml -Path $Path -XPath $Xpath | FOREACH {$_.node.InnerXML}

        $Index = $Index + 1
    } ELSE {
        $Computer.Key = 'No Ping'
        $Computer.ID = 'No Ping'
    }
    
    $Computer
}
