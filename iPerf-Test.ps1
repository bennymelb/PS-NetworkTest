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
log -logstring "Starting iperf test against $target"

$Counter = 1

Do {
    
    log -logstring "Round $Counter"

    # Start the test
    $o = .\iperf3.exe -c $target 

    # parse the output
    $OutputArr = $o -split '                  '

    foreach ($line in $OutputArr) {
        log -logstring "$line"
    }

    $Counter++

    Start-Sleep -Seconds 300 

} while ($Counter -ge 0)
