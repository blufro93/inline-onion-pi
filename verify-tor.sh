#!/bin/sh

## MIT License:

## Copyright (C) 2014 blufro93

## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONNFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

# get the entry guards from arm
echo "GETINFO entry-guards" | arm -p | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > entry-guards
# strip out only the finger prints
cat entry-guards | grep -Eo "[A-F0-9]+[\~\=]" | grep -Eo "[A-F0-9]+" > fingerprints
# get the IPs from the fingerpints
for i in `cat fingerprints`; do echo "/info $i" | arm -p | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"; done | grep "address" | grep -Eo "[0-9\.]{2,}" | grep "\." > ips
# construct our tcpdump inerface
interface="eth0 not host `head -n 1 ips`"
for i in `tail -n +2 ips`; do interface="$interface and not host $i"; done

# log who we should be connected to
echo "Your current tor entry nodes are:"
cat ips

read -p "Press ENTER to continue ..."

#cleanup
rm entry-guards
rm fingerprints
rm ips

# tcpdump
tcpdump -n -t -q  -p -i $interface

