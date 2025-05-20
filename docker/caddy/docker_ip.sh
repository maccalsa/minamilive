#!/bin/bash

ip addr show docker0 | grep -oP 'inet \K[\d.]+' | head -n1