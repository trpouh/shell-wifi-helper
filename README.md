# shell-wifi-helper
a minimal shell script to encapsulate a couple useful wifi operations.

using it is easy:

````shell
~$ sh wifi.sh <operation> [opts]
````

e.g. connecting to the ssid `mywifi` with the password `123456789`
````shell
~$ sh wifi.sh connect mywifi 123456789
````

## operations

* `connect <ssid> [password]`
* `disconnect`
* `is_connected`; returns `true` or `false`
* `get_ssids`
* `start_hotspot <ssid>`
* `stop_hotspot`
