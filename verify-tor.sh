#assumes tcpdump and tor-arm packages are installed

# get the entry guards from arm
echo "GETINFO entry-guards" | arm -p | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > entry-guards
# strip out only the finger prints
cat entry-guards | grep -Eo "[A-F0-9]+[\~\=]" | grep -Eo "[A-F0-9]+" > fingerprints
# get the IPs from the fingerpints
for i in `cat fingerprints`; do echo "/info $i" | arm -p | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"; done | grep "address" | grep -Eo "[0-9\.]{2,}" | grep "\." > ips
# construct our tcpdump inerface
interface="eth0 not host `head -n 1 ips`"
for i in `tail -n + 2 ips`; interface="$interface and not host $i"; done
echo $interface

# tcpdump
