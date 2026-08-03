function Reset-GitConnection {
    param(
        [switch]$set
    )

    if ($set) {
        git config --global --set http.proxy
        git config --global --set https.proxy
    } else {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
    }
}
