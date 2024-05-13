Import-Module -Name 'C:\Programs\NAVI.DCMTK.PS1'

#$Command = "$DCMTK.CFIND --verbose --worklist --aetitle HOLLOGIC_SXCH --call DMWL_AE 162.3.7.86 104 -k 0010,0010 -k (0040,0001)[0].0040,0001='<AET OF DEVICE>'
#$Command = "$($DCMTK.CFIND) --verbose --worklist --aetitle HOLOGIC_SXCH --call DMWL_AE 162.3.7.86 104 -k 0010,0010 -k (0040,0001)[0].0040,0001='HOLOGIC_SXCH'"
$Command = "$($DCMTK.CFIND) --verbose --worklist --aetitle HOLOGIC_SXCH --call DMWL_AE 162.3.7.86 104 -k 0010,0010"
$Command
PAUSE

#$ReturnCollection = Invoke-Expression -Command $Command
Invoke-Expression -Command $Command
