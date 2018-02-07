
#### Begin by getting the SQL list and capturing name and uptimes ####


$s = Get-Date

$SqlList = gc 'C:\SQLReportingWeb\Scheduled_Scripts\SQLList.txt'


#### SQL Query ####
$MyQuery = "USE master;

SET
NOCOUNT ON

DECLARE @crdate DATETIME, @hr VARCHAR(50), @min VARCHAR(5)

SELECT @crdate=crdate FROM sysdatabases WHERE NAME='tempdb'
SELECT @hr=(DATEDIFF ( mi, @crdate,GETDATE()))/60

IF ((DATEDIFF ( mi, @crdate,GETDATE()))/60)=0

	SELECT @min=(DATEDIFF ( mi, @crdate,GETDATE()))

ELSE

	SELECT @min=(DATEDIFF ( mi, @crdate,GETDATE()))-((DATEDIFF( mi, @crdate,GETDATE()))/60)*60

SELECT @hr+' hours & '+@min+' minutes' as UpTime, @hr as UpTimeHours, @min as UpTimeMinutes
"
#### SQL Query End ####


$DataSet = foreach ($SqlServer in $SqlList)
{
$UpTime = Invoke-Sqlcmd -ServerInstance $SqlServer -Query $MyQuery

$Result = New-Object System.Object
$Result | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $SqlServer
$Result | Add-Member -MemberType NoteProperty -Name "UpTimeHours" -Value $UpTime.UpTimeHours

$Result
}


#### Uptime needs to be an integer
$DataSet | % {$_.UptimeHours = [int]$_.UptimeHours} 


#### Put the data into 7 columns
$Rowtest = 1
$CellData = foreach ($Item in ($dataset|Sort-Object UptimeHours))
{

if ($Rowtest -gt 6)
    {
    $Rowtest = 0
    $Result = New-Object psobject
    $Result | Add-Member -MemberType NoteProperty -Name "Instance" -Value $Item.ServerName
    $Result | Add-Member -MemberType NoteProperty -Name "Uptime" -Value $Item.UpTimeHours
    $Result | Add-Member -MemberType NoteProperty -Name "Col" -Value $Rowtest
    $Rowtest++
    }
else
    {
    $Result = New-Object psobject
    $Result | Add-Member -MemberType NoteProperty -Name "Instance" -Value $Item.ServerName
    $Result | Add-Member -MemberType NoteProperty -Name "Uptime" -Value $Item.UpTimeHours
    $Result | Add-Member -MemberType NoteProperty -Name "Col" -Value $Rowtest
    $Rowtest++
    
    }
    $Result
} 




#### Format the cell data into HTML
$Col = 1
$count = 0
$CellResult =  foreach ($Item in $CellData)

    {
    $CellDataFormatted = New-Object psobject
    
    #### We want different colours based on values
    if ($Item.UpTime -lt "48")
        {
        $tdStyle = "<td style=`"background-color:rgb(255,157,157)`">"
        }
    elseif ($Item.UpTime -lt "120" -and $Item.UpTime -gt "47") 
        {
        $tdStyle = "<td style=`"background-color:rgb(255,231,126)`">"
        }
    else 
        {
        $tdStyle = "<td>"
        }


        if ($count -gt $Item.col)
        {
            
        $ServerCellData = "$tdStyle"
        $ServerCellData = $ServerCellData + "<p style=`"font-weight: bold;margin-top: 3px;margin-bottom: 3px`">" + $Item.Instance + "</p>"
        $ServerCellData = $ServerCellData + "<p style=`"margin-top: 3px;margin-bottom: 3px`">" + $Item.Uptime + "</p>"
        $ServerCellData = $ServerCellData + "</td>`n"
        $CellDataFormatted | Add-Member -MemberType NoteProperty -name "CellData" -Value $ServerCellData
        $CellDataFormatted | Add-Member -MemberType NoteProperty -Name "ColIndex" -Value $Col
        
        

        $count = 0
        $col++

        }
        else
        {
        $ServerCellData = "$tdStyle"
        $ServerCellData = $ServerCellData + "<p style=`"font-weight: bold;margin-top: 3px;margin-bottom: 3px`">" + $Item.Instance + "</p>"
        $ServerCellData = $ServerCellData + "<p style=`"margin-top: 3px;margin-bottom: 3px`">" + $Item.Uptime + "</p>"
        $ServerCellData = $ServerCellData + "</td>`n"
        $CellDataFormatted | Add-Member -MemberType NoteProperty -name "CellData" -Value $ServerCellData
        $CellDataFormatted | Add-Member -MemberType NoteProperty -Name "ColIndex" -Value $Col
        $count++
        }

    $CellDataFormatted
    
    }


#### Rattle through the formated list and order them into rows (yes rows, not columns...it was how i put it together)
$colcount = 1
$FormattedTable = do
                {
    "<tr>`n"
        
        foreach ($item in $CellResult)
            {
                if ($item.ColIndex -eq $colcount)
                    {$item.CellData}
            }
    "</tr>`n"
    $colcount++    
                }
                    until ($colcount -gt 18)


#### Build the web page
$e = Get-Date
$TimeTaken = ($e - $s).TotalSeconds


$a = "<!DOCTYPE html PUBLIC "
$a = $a + "-//W3C//DTD XHTML 1.0 Strict//EN"  
$a = $a + "`"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd`">"
$a = $a + "<html xmlns=`"http://www.w3.org/1999/xhtml`">"

$b = "<head><style>"
$b = $b + "BODY{background-color:rgb(224,250,250);}"
$b = $b + "TABLE{border-width: 3px;border-style: solid;border-color: black;border-collapse: collapse;}"
$b = $b + "TH{border-width: 3px;padding: 0px;border-style: solid;border-color: grey;background-color:rgb(175,236,237)}"
$b = $b + "TD{margin-top: 3px; margin-bottom: 3px;border-width: 3px;padding: 0px;border-style: solid;border-color: white;background-color:rgb(217,250,219);text-align: center}"
$b = $b + "</style></head>"

$c = "<H2>SQL Uptime</H2>"
$c = $c + "<p>Report Last Run Date: " + $e + "</p>"
$c = $c + "<p>Querying " + $SqlList.count + " SQL Servers - please allow approx 5 seconds for each server for the report to run</p>"
$c = $c + "<p>Estimated max time - " + $SqlList.count * 5 + " seconds</p>"
$c = $c + "<p>Script Run Time (seconds): " + $TimeTaken + "</p>"


$Webpage = $a + "`n`n"
$Webpage = $Webpage + $b + "`n`n"
$Webpage = $Webpage + $c + "`n`n"
$Webpage = $Webpage + "<table>`n"
$Webpage = $Webpage + "<colgroup><col><col><col><col><col><col></colgroup>`n"
$Webpage = $Webpage + "<tr><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th>6</th><th>7</th></tr>`n"
$Webpage = $Webpage + $FormattedTable
$Webpage = $Webpage + "</table></body></html>"


$Webpage | Out-File C:\SQLReportingWeb\SQLReports\SQLWallBoard\SQLWallBoard.html

