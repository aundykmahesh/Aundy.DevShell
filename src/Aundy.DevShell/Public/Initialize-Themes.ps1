function Initialize-Themes {
    $themesPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\Themes'
    $oneDrivePictures = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive\Pictures\Wallpapers\Desktop\Theme'

    if (-not(Test-Path -Path $themesPath)) {
        New-Item -ItemType Directory -Path $themesPath
    }

    Copy-Item -Path (Join-Path -Path $oneDrivePictures -ChildPath 'MyDark.theme') -Destination $themesPath
    Copy-Item -Path (Join-Path -Path $oneDrivePictures -ChildPath 'MyMedium.theme') -Destination $themesPath
}
