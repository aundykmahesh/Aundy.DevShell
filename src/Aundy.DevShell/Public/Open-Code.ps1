function Open-Code {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = '.'
    )
    code $Path
}
