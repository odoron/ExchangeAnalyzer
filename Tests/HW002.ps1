#requires -Modules ExchangeAnalyzer

#This function checks to see if the Exchange Server power management is set to High Performance
Function Run-HW002()
{

   [CmdletBinding()]
    param()

    $TestID = "HW002"
    Write-Verbose "----- Starting test $TestID"

    $PassedList = @()
    $FailedList = @()
    $WarningList = @()
    $InfoList = @()
    $ErrorList = @()

    foreach ($server in $exchangeservers) {
        $name = $server.name

        # Get server power plan
        invoke-command -ComputerName $name -ScriptBlock {powercfg -l}
        $HighPerf = invoke-command -ComputerName $name -ScriptBlock {powercfg -l | %{if($_.contains("High performance")) {$_.split()[3]}}}
        $CurrPlan = invoke-command -ComputerName $name -ScriptBlock {$(powercfg -getactivescheme).split()[3]}
        
        # Validate if the server is set to use the High Performance power plan
        if ($CurrPlan -eq $HighPerf) {
            write-verbose "The power plan now is set to High Performance."
            $PassedList += $($name)
        } else {
            write-verbose "The power plan is not set to High Performance and is currently set to $currplan."
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

Run-HW002