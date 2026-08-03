function Clear-GitWorkspace {
    git branch | Where-Object { 
        -not ($_.StartsWith("*") -or ('master','main' -contains $_.Trim())) 
    } | ForEach-Object {
        Write-Output "Deleting branch $_"
        git branch -D $_.Trim()
    } 

    Write-Output 'The remaining branches are'
    git branch
}
