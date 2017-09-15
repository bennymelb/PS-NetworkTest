###############################################
########   Define the necessary var    ########
###############################################

Param (

    # Set the working directory
    [string]$WorkDir = (Split-Path $MyInvocation.MyCommand.Path),

    # Set the logfile
    [string]$logfile = [io.path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name) + ".log",

    # Source path
    [string]$target = ".\BJ-iPerf-Test.log",

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
$speedarr = @()

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

    if ($line -like "*sender*")
    {
        $pointer = $($AllLog.IndexOf($line)) -1         
        $log = $AllLog[$pointer]
        $logarr = $log.Split(" ")
        $speed = [decimal]$logarr[-2]        
        $unit = $logarr[-1]
        #write-host "before $speed $unit"        
        if ($unit -like "*Mbits*")
        {
            # Convert the speed from mbps to kbps
            $speed = $speed * 1000
        }                
        #write-host "after $speed Kbit/sec"        
        $speedarr += $speed        
        #Read-host "Press enter to continue"
    }
}

# average speed
$avg = ($speedarr | Measure-Object -Average)
$max = ($speedarr | Measure-Object -Maximum)
$min = ($speedarr | Measure-Object -Minimum)

Write-host "The test start from $Starttimestamp and finish at $endtimestamp Min: $($min.Minimum) Kbit/sec || Max: $($max.Maximum) Kbit/sec || Average: $([math]::Round($avg.Average)) Kbit/sec"

Read-Host "Press enter to continue"
