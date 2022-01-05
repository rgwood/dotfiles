$"Querying API(char nl)(char nl)"
let json = (curl https://api.github.com/repos/jesseduffield/lazygit/releases/latest)
let latestLinuxAsset = ($json | from json | get assets | where name =~ "Linux_x86_64")
let url = ($latestLinuxAsset | get browser_download_url)
let fileName = ($latestLinuxAsset | get name)

$"(char nl)Downloading ($url)(char nl)(char nl)"
curl --location -O $url

$"Extracting...(char nl)"
tar xf $fileName

$"Copying to bin(char nl)"
cp lazygit ~/bin/lazygit
