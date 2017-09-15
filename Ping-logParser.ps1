###############################################
########   Define the necessary var    ########
###############################################

Param (

    # Set the working directory
    [string]$WorkDir = (Split-Path $MyInvocation.MyCommand.Path),

    # Set the logfile
    [string]$logfile = [io.path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name) + ".log",

    # Source path
    [string]$target = ".\BJ-Ping-Test.log",

    # Task name for the email alert, default is the script name
    [string]$TaskName = $MyInvocation.MyCommand,

    # custom library location 
    [string]$lib = (join-path $WorkDir "lib")
)

# if library location is a relative path, append the working directory in front to make it a absolute path
If (!([System.IO.Path]::IsPathRooted($lib)))
{
    $lib = (join-path $WorkDir $lib)        
}

###############################################
########         Set ENV Var           ########
###############################################

# Generate a GUID as a session ID
$env:SessionID = [System.Guid]::NewGuid().ToString()

$env:logfile = $logfile

$env:app = $MyInvocation.MyCommand

$env:PSModulePath = $env:PSModulePath + ";$lib"

###############################################
########    Load necessary module      ########
###############################################

# Load the logging module
Import-Module logging.psm1 -ErrorAction Stop

Import-Module Folder.psm1 -ErrorAction Stop

###############################################
########       Start of the script     ########
###############################################

# Change to working Directory
Write-Host "Changing the working directory to $WorkDir ..."
Set-Location $WorkDir -ErrorVariable err
if (!$err)
{
    Write-Host "Successfully changed the working directory to $WorkDir"
}
else
{
    Write-Host -ForegroundColor Red "Failed to change the working directory to $WorkDir"
    Write-Host -ForegroundColor Red "$err"
    Write-Host -ForegroundColor Red "This is a fatal error, exiting the script ..."
    Exit 1
}

# Store the content in arr for parsing
$AllLog = Get-Content $target
$msarr = @()
$pingrequest = 0
$errorcount = 0

ForEach ($line in $AllLog)
{   
    if ( $($AllLog.IndexOf($line)) -eq 0 )
    {
        # Get the start Time stamp
        $startlogarr = $line.Split(" ")
        $Startmonth = $startlogarr[0]
        $Startday = $startlogarr[1]
        $Startyear = $startlogarr[2]
        $Starttime = $startlogarr[3]
        $Starttimestamp = $Startmonth + " " + $Startday + " " + $Startyear + " " + $Starttime
    }   

    If ( $line -eq $AllLog[-1] )
    {
        # Get the finish Time stamp
        $endlogarr = $line.Split(" ")
        $endmonth = $endlogarr[0]
        $endday = $endlogarr[1]
        $endyear = $endlogarr[2]
        $endtime = $endlogarr[3]
        $endtimestamp = $endmonth + " " + $endday + " " + $endyear + " " + $endtime
   
    }

    # Get the number of ping request sent
    if ($line -like "*pinging*")
    {
        $pingrequest++
    }

    # Get the number of error 
    if ($line -like "*Error*")
    {
        $errorcount++
    }

    # Find successful ping reply
    if ($line -like "*Reply*")
    {
        $logarr = $line.Split(" ")
        $ms = $logarr[-2]        
        $ms = [decimal]($ms.Split("="))[1]  
        $msarr += $ms        
    }
}

# average ms
$avg = ($msarr | Measure-Object -Average)
$max = ($msarr | Measure-Object -Maximum)
$min = ($msarr | Measure-Object -Minimum)

Write-host "The test start from $Starttimestamp and finish at $endtimestamp"
write-host "Total request sent: $pingrequest || Number of Error: $errorcount || percentage of packet lost $([Math]::Round($($errorcount / $pingrequest * 100),2))%"
write-host "Min: $($min.Minimum)ms || Max: $($max.Maximum)ms || Average: $([math]::Round($avg.Average))ms"

Read-Host "Press enter to continue"
