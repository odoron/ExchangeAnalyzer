#requires -Modules ExchangeAnalyzer

#This function checks to see if the Windows Firewall Service is set to a value other than Automatic
Function Run-WSSRV007()
{

   [CmdletBinding()]
    param()

    $TestID = "WSSRV007"
    Write-Verbose "----- Starting test $TestID"

    $PassedList = @()
    $FailedList = @()
    $WarningList = @()
    $InfoList = @()
    $ErrorList = @()

    foreach ($server in $exchangeservers) {
        # Set Variables for the current loop
        $name = $server.name
        $ConnectionError = $false
        $tryWMI = $false
        $FirewallState = $null

        try {
            $FirewallState = (Get-CIMInstance -Class win32_service -filter "name = 'mpssvc'" -ComputerName $name -erroraction STOP).startmode
        } catch {
            $tryWMI = $true
            Write-Verbose "$($TestID): Was not able to acquire information for $name via CIM"    
        }
        if ($tryWMI) {
            try {
                $FirewallState = (Get-WmiObject -Class win32_service -filter "name = 'mpssvc'" -ComputerName $name -erroraction STOP).startmode
            } catch {
                Write-Verbose "$($TestID): Was not able to acquire information for $name via WMI"    
                $ConnectionError = $true
            }
        }

        If ($ConnectionError -eq $false) {
                       
            # Validate if the firewall service is set to Automatic on the server
            if ($FirewallState -eq "Auto") {

                # The Windows Firewall service's startup mode is set to Automatic
                write-verbose "The firewall service on $name is set to Automatic."
                $PassedList += $($name)
            } else {

                # Fail the server for having the service startup mode set to anything but Automatic
                write-verbose "The firewall service on $name is set to Manual or Disabled and should be set to Automatic."
                $FailedList += $($name)
            }
        } else {

            # Script failed to connect to the server and is added to the warning list
            write-verbose "There was an issue connecting to the $name server. "
            $WarningList += $($name)
        }
    }

    #Roll the object to be returned to the results
    $ReportObj = Get-TestResultObject -ExchangeAnalyzerTests $ExchangeAnalyzerTests `
                                      -TestId $TestID `
                                      -PassedList $PassedList `
                                      -FailedList $FailedList `
                                      -WarningList $WarningList `
                                      -InfoList $InfoList `
                                      -ErrorList $ErrorList `
                                      -Verbose:($PSBoundParameters['Verbose'] -eq $true)

    return $ReportObj
}

Run-WSSRV007