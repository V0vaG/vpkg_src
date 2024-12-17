#!/bin/bash
path=$(pwd)
sed -i "s|@@PATH@@|${1}|g" ./vpkg_3.3.6.sh
