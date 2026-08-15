@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        # Intentional for the beginner-facing, colored terminal interface.
        'PSAvoidUsingWriteHost'

        # Refresh-Path is a private helper, not an exported command.
        'PSUseApprovedVerbs'
    )
}
