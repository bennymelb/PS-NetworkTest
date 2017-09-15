###############################################
########   Define the necessary var    ########
###############################################

Param (

    # Set the working directory
    [string]$WorkDir = (Split-Path $MyInvocation.MyCommand.Path),

    # Set the logfile
    [string]$logfile = [io.path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name) + ".log",

    # Source path
    [string]$target = "localhost",

    # number of ping, Default is 4, -1 means no limit
    [int16]$number = 4,

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

# Write a start line to improve readability
log -logstring "******************* Task triggered by $(whoami) *******************"
log -logstring "Starting ping test against $target"

$Counter = $number
$request = 1

$StatusCodes = @{
    [uint32]0     = 'Success';
    [uint32]11001 = 'Buffer Too Small';
    [uint32]11002 = 'Destination Net Unreachable';
    [uint32]11003 = 'Destination Host Unreachable';
    [uint32]11004 = 'Destination Protocol Unreachable';
    [uint32]11005 = 'Destination Port Unreachable';
    [uint32]11006 = 'No Resources';
    [uint32]11007 = 'Bad Option';
    [uint32]11008 = 'Hardware Error';
    [uint32]11009 = 'Packet Too Big';
    [uint32]11010 = 'Request Timed Out';
    [uint32]11011 = 'Bad Request';
    [uint32]11012 = 'Bad Route';
    [uint32]11013 = 'TimeToLive Expired Transit';
    [uint32]11014 = 'TimeToLive Expired Reassembly';
    [uint32]11015 = 'Parameter Problem';
    [uint32]11016 = 'Source Quench';
    [uint32]11017 = 'Option Too Big';
    [uint32]11018 = 'Bad Destination';
    [uint32]11032 = 'Negotiating IPSEC';
    [uint32]11050 = 'General Failure'
}

# https://msdn.microsoft.com/en-us/library/aa394350(v=vs.85).aspx

Do {
    
    log -logstring "[$request] pinging $Target ..."

    # Time the ping to put a delay if it finish within 1 sec, we dont want to turn this into a DOS attach
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Start the test
    $ping = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$target'" -ErrorVariable err

    # Catch any WmiObject Error
    if ($err)
    {
        log-error "$err"
    }
    else 
    {
        # Test if the test successful
        if ( $ping.statuscode -eq 0 )
        {
            log "Reply from $($target): BufferSize=$($ping.BufferSize) ReplySize=$($ping.ReplySize) time=$($ping.ResponseTime) TTL=$($ping.ResponseTimeToLive)"
        }
        else 
        {
            Write-Warning "The error code is $($ping.StatusCode)"
            $Result = $StatusCodes[$ping.StatusCode]
            log-error "$Result"
        }    
        
    }
    
    $Counter--
    $request++
    $stopwatch.Stop()

    If ($stopwatch.Elapsed.Seconds -le 0)
    {
        Start-Sleep -Seconds 1         
    }

    
} until ($Counter -eq 0)
