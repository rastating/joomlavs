# joomlavs
A black box, Ruby powered, Joomla vulnerability scanner

## What is it?
JoomlaVS is a Ruby application that can help automate assessing how vulnerable a Joomla installation is to exploitation. It supports basic finger printing and can scan for vulnerability to both extensions and vulnerabilities that exist within Joomla itself.

## How to install
JoomlaVS has so far only been tested on Debian, but the installation process should be similar across most operating systems.

1. Ensure Ruby [2.1 or above] is installed on your system
2. Clone the source code using ```git clone https://github.com/rastating/joomlavs.git```
3. Install bundler and required gems using ```sudo gem install bundler && bundle install```

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
Advanced options
    --follow-redirection   Automatically follow redirections
    --no-colour            Disable colours in output
    --proxy                <[protocol://]host:port> HTTP, SOCKS4 SOCKS4A and SOCKS5 are supported. If no protocol is given, HTTP will be used
    --proxy-auth           <username:password> The proxy authentication credentials
    --threads              The number of threads to use when multi-threading requests
    --user-agent           The user agent string to send with all requests
```
