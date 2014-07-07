echo "GETINFO entry-guards" | arm -p | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > entry-guards
cat entry-guards | -Eo "[A-F0-9]+\~" | grep -Eo "[A-F0-9]+" > fingerprints
for i in `cat entry-guards`; do echo "\info $i" | arm -p | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"; done | grep "address" | grep -Eo "[0-9\.]{2,}" | grep "\." > ips
