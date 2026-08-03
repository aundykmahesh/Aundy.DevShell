function CodeCleanest {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = '.'
    )
    code --disable-extensions --profile "Clean" $Path
}
