function Restart-WSL {
    # Timeout wsl --shutdown in case it hangs
    $wsl = Start-Process -WindowStyle Hidden wsl -ArgumentList --shutdown -PassThru
    
    # If wsl should print something, it will be piped to the Null device
    # $wsl.StandardOutput | Out-Null
    # $wsl.StandardError | Out-Null
    
    # Wait for wsl --shutdown to exit
    $millisecondsPerSecond = 1000
    $timeout = 10 * $millisecondsPerSecond
    $wslExited = $wsl.WaitForExit($timeout)

    # If wsl --shutdown didn't exit, kill it
    if (-not $wslExited) {
        $wsl.Kill()
        Write-Error "Shutting down wsl timed out after $timeout s"
    }

    # If wsl --shutdown exited with an error, print the error
    if ($wsl.ExitCode -ne 0) {
        Write-Error "Shutting down wsl exited with code $($wsl.ExitCode)"
    }

    # vmcompute is the service that runs the WSL2 VM
    $command = "Restart-Service vmcompute"
    try { 
        Write-Output "Starting new elevated PowerShell process..."
        # Restarting vmcompute needs admin privileges
        Start-Process -WindowStyle Hidden -Wait powershell -Verb runAs $command
        Write-Output "WSL has been restarted."
    }
    catch {
        # If the user is not an admin and cancels the UAC prompt, this block will be executed
        Write-Error "Failed to start a new PowerShell as administrator."
        Write-Error "Please restart the computer or run the following command in an eliviated shell:"
        Write-Error ""
        Write-Error "`"$command`""
    }
}
