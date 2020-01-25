function wat
    if type --quiet tldr
        tldr "$argv"
    else
        curl cht.sh/"$argv"
    end
end
