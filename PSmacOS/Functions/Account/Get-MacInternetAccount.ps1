<#
    .SYNOPSIS
        Get the internet accounts configured on the local macOS system.

    .DESCRIPTION
        Return one object per account configured in System Settings >
        Internet Accounts (e.g. iCloud, Google, Exchange or CalDAV/CardDAV
        accounts), read directly from the accountsd database at
        ~/Library/Accounts/Accounts4.sqlite. There is no public API for this
        information.

        Because the database is protected by macOS privacy protections
        (TCC), the application running PowerShell (e.g. Terminal, iTerm2 or
        Visual Studio Code) must be granted Full Disk Access in System
        Settings > Privacy & Security. If access is not yet granted, this
        function opens the correct Privacy & Security pane and throws an
        error explaining what to do; simply run the command again after
        granting access.

    .INPUTS
        None.

    .OUTPUTS
        PSmacOS.InternetAccount. Internet account information.

    .EXAMPLE
        PS /> Get-MacInternetAccount
        Get all internet accounts configured on the local macOS system.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Get-MacInternetAccount
{
    [CmdletBinding()]
    [OutputType('PSmacOS.InternetAccount')]
    param ()

    # Exit if executed on a non-macOS platform
    if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
    {
        throw 'This function is only supported on macOS platforms.'
    }

    $databasePath = Join-Path -Path $HOME -ChildPath 'Library/Accounts/Accounts4.sqlite'

    if (-not (Test-Path -Path $databasePath))
    {
        throw "The internet accounts database was not found at '$databasePath'."
    }

    $query = @'
SELECT
    ZACCOUNTTYPE.ZACCOUNTTYPEDESCRIPTION AS AccountType,
    ZACCOUNT.ZACCOUNTDESCRIPTION         AS AccountDescription,
    ZACCOUNT.ZUSERNAME                   AS UserName,
    ZACCOUNT.ZOWNINGBUNDLEID             AS OwningBundleID
FROM ZACCOUNT
INNER JOIN ZACCOUNTTYPE ON ZACCOUNT.ZACCOUNTTYPE = ZACCOUNTTYPE.Z_PK;
'@

    $output = & sqlite3 -json -readonly $databasePath $query 2>&1

    if ($LASTEXITCODE -ne 0)
    {
        $errorMessage = $output -join "`n"

        if ($errorMessage -match 'authorization denied')
        {
            & open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'

            throw 'Reading the internet accounts database requires Full Disk Access. Grant it to the application running PowerShell (e.g. Terminal, iTerm2 or Visual Studio Code) in the System Settings window that was just opened, under Privacy & Security > Full Disk Access, then run this command again.'
        }

        throw "Failed to read the internet accounts database: $errorMessage"
    }

    $json = $output -join "`n"

    if ([System.String]::IsNullOrWhiteSpace($json))
    {
        return
    }

    foreach ($account in (ConvertFrom-Json -InputObject $json))
    {
        Write-Output ([PSCustomObject] @{
            PSTypeName      = 'PSmacOS.InternetAccount'
            AccountType     = $account.AccountType
            Description     = $account.AccountDescription
            UserName        = $account.UserName
            OwningBundleID  = $account.OwningBundleID
        })
    }
}
