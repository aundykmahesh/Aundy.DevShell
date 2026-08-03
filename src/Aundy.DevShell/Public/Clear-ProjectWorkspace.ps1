function Clear-ProjectWorkspace {
    [CmdletBinding()]
    param()

    @( 'obj', 'bin' ) | ForEach-Object {
        Get-ChildItem -Path . -Filter $_ -Attributes Directory -Recurse | ForEach-Object {
            Remove-Item -Path $_ -Recurse -Force
        }
    }
}
