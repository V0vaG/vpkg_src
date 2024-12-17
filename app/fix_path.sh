#!/bin/bash
path=$(pwd)
sed -i "s|@@PATH@@|${path}|g" ./vpkg_3.3.6.sh
