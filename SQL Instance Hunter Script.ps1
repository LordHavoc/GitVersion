<#Prerequesites - You must have both Invoke-Parallel and Get-SQLInstance functions loaded. Both can be obtained on Microsoft Technets Powershell
Library
#>

<#Clearing the variables before we begin#>
$Range = ""
$VLanSelection = ""


$Range = 1..255
$VLanSelection = ('192.168.96','192.168.97','159.170.208','159.170.209','159.170.210','159.170.211') <#<---Put your vlans in here#>



<#Build the results and output it to the variable $FinalResult#>
$FinalResult = foreach ($VLan in $VLanSelection)
{


$myIPList = foreach ($r in $Range) {"{0}.{1}" -F $VLan,$r}


<#Get the information about SQL from all IPs in the vlan, doing it using multiple threads#>
       $SqlInfo = $myIPList | Invoke-Parallel -Throttle 100 -ImportFunctions {Get-SQLInstance $_ -WarningAction SilentlyContinue | SELECT Computername,Instance,Version,Skuname,Nodes} 


$FullInfo = foreach ($Item in $SqlInfo)
    {



      #Defining the result object to act as a custom table
      $Result = New-Object System.Object


       #Building the object column by column
       $Result | Add-Member -MemberType NoteProperty -Name "IP" -Value $Item.Computername | select -ExpandProperty IP
       $Result | Add-Member -MemberType NoteProperty -Name "DNSName" -Value ($Item.Computername | Resolve-DnsName -ErrorAction SilentlyContinue | select -ExpandProperty NameHost)
       $Result | Add-Member -MemberType NoteProperty -Name "InstanceName" -Value $Item.Instance
       $Result | Add-Member -MemberType NoteProperty -Name "Version" -Value $Item.Version
       $Result | Add-Member -MemberType NoteProperty -Name "Edition" -Value $Item.Skuname
       $Result | Add-Member -MemberType NoteProperty -Name "ClusterNodes" -Value $Item.Nodes | Select -ExpandProperty Nodes

       $Result
    }

$FullInfo

}


$FinalResult
$FinalResult.count