# joomlavs [![Build Status](https://travis-ci.org/rastating/joomlavs.svg?branch=master)](https://travis-ci.org/rastating/joomlavs) [![Code Climate](https://codeclimate.com/github/rastating/joomlavs/badges/gpa.svg)](https://codeclimate.com/github/rastating/joomlavs) [![Dependency Status](https://gemnasium.com/badges/github.com/rastating/joomlavs.svg)](https://gemnasium.com/github.com/rastating/joomlavs)
A black box, Ruby powered, Joomla vulnerability scanner

## What is it?
JoomlaVS is a Ruby application that can help automate assessing how vulnerable a Joomla installation is to exploitation. It supports basic finger printing and can scan for vulnerabilities in components, modules and templates as well as vulnerabilities that exist within Joomla itself.

## License
Copyright (C) 2015 rastating

Running JoomlaVS against websites without prior mutual consent may be illegal in your country. The author and parties involved in its development accept no liability and are not responsible for any misuse or damage caused by JoomlaVS.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

## How to install
JoomlaVS has so far only been tested on Debian, but the installation process should be similar across most operating systems.

1. Ensure Ruby [2.2.6 or above] is installed on your system
2. Clone the source code using ```git clone https://github.com/rastating/joomlavs.git```
3. Install bundler and required gems using ```sudo gem install bundler && bundle install```

## Troubleshooting Installation
If you have issues installing JoomlaVS' dependencies (in particular, Nokogiri), first make sure you have all the tooling necessary to compile C extensions:

```
sudo apt-get install build-essential patch
```

It’s possible that you don’t have important development header files installed on your system. Here’s what you should do if you should find yourself in this situation:

```
sudo apt-get install ruby-dev zlib1g-dev liblzma-dev libcurl4-openssl-dev
```

## How to use
The only required option is the ```-u``` / ```--url``` option, which specifies the address to target. To do a full scan, however, the ```--scan-all``` option should also be specified, e.g. ```ruby joomlavs.rb -u yourjoomlatarget.com --scan-all```.

A full list of options can be found below:

```
usage: joomlavs.rb [options]
Basic options
    -u, --url              The Joomla URL/domain to scan.
    --basic-auth           <username:password> The basic HTTP authentication credentials
    -v, --verbose          Enable verbose mode
Enumeration options
    -a, --scan-all         Scan for all vulnerable extensions
    -c, --scan-components  Scan for vulnerable components
    -m, --scan-modules     Scan for vulnerable modules
    -t, --scan-templates   Scan for vulnerable templates
    -q, --quiet            Scan using only passive methods
Advanced options
    --follow-redirection   Automatically follow redirections
    --no-colour            Disable colours in output
    --proxy                <[protocol://]host:port> HTTP, SOCKS4 SOCKS4A and SOCKS5 are supported. If no protocol is given, HTTP will be used
    --proxy-auth           <username:password> The proxy authentication credentials
    --threads              The number of threads to use when multi-threading requests
    --user-agent           The user agent string to send with all requests
```
