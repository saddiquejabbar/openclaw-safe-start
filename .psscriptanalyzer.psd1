@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        # Intentional for the beginner-facing, colored terminal interface.
        'PSAvoidUsingWriteHost'

        # Refresh-Path is a private helper, not an exported command.
        'PSUseApprovedVerbs'

        # These are private script functions; Safe Start provides its own
        # explicit -DryRun mode instead of exporting cmdlets with -WhatIf.
        'PSUseShouldProcessForStateChangingFunctions'

        # Internal function names are not an exported PowerShell API.
        'PSUseSingularNouns'

        # PSScriptAnalyzer does not follow the script-level switch into the
        # nested prompt helpers that use it.
        'PSReviewUnusedParameter'
    )
}
