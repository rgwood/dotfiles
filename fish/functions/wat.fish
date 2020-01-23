function wat
    if type --quiet tldr
        tldr -t ocean "$argv"
    else
        curl cht.sh/"$argv"
    end
end
