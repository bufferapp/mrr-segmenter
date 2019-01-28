#!/bin/sh

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny:shiny /var/log/shiny-server

#Make sure the shiny user can write to /root
chown shiny:shiny /root

#Pass env vars to shiny
env > /home/shiny/.Renviron

exec shiny-server 2>&1
