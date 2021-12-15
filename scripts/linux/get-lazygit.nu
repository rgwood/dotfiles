echo $"Querying API(char nl)(char nl)"
let latestLinuxAsset = (curl https://api.github.com/repos/jesseduffield/lazygit/releases/latest | from json | get assets | where name =~ "Linux_x86_64")

let url = ($latestLinuxAsset | get browser_download_url)

let fileName = ($latestLinuxAsset | get name)

echo $"(char nl)Downloading ($url)(char nl)(char nl)"
curl --location -O $url

echo $"Extracting... (char nl)"

tar xf $fileName

echo $"Copying to bin(char nl)"

cp lazygit ~/bin/lazygit
