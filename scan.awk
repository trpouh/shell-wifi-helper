# https://stackoverflow.com/questions/17809912/parsing-iw-wlan0-scan-output/17810551
$1 == "BSS" && $2 != "Load:" {
    MAC = $2
    wifi[MAC]["enc"] = "Open"
}
$1 == "SSID:" {
    wifi[MAC]["SSID"] = $2
}

$1 == "freq:" {
    wifi[MAC]["freq"] = $NF
}

$1 == "signal:" {
    wifi[MAC]["sig"] = $2 " " $3
}

$1 == "WPA:" {
    wifi[MAC]["enc"] = "WPA"
}

$1 == " +WPA" {
    wifi[MAC]["enc"] = "WPA"
}

$1 == "RSN:" {
    wifi[MAC]["enc"] = "WPA2"
}

END {
    printf "%s;%s;%s;%s\n","SSID", "Frequency","Signal","Encryption"

    for (w in wifi) {
        printf "%s;%s;%s;%s\n",wifi[w]["SSID"],wifi[w]["freq"],wifi[w]["sig"],wifi[w]["enc"]
    }
}
