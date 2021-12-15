echo $"Querying API(char nl)"
let url = (curl https://api.github.com/repos/jesseduffield/lazygit/releases/latest | from json | get assets | where name =~ "Linux_arm64" | get browser_download_url)

echo $"(char nl)Downloading ($url)(char nl)(char nl)"
curl --location -O $url
