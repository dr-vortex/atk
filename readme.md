# Apache Tool Kit (ATK)

ATK is a simple script that allows you to easily install and set up a full web server (including SSL and databases) in a matter of seconds.

## Usage

First, clone the github repository: `git clone https://github.com/dr-vortex/atk.git`
Then install ATK: `atk/install.sh`
After that, you can use ATK. Run `atk --help` to get details on commands.

### Setting up a web server

After installing ATK, running the following commands can get you a running web server in seconds:
```sh
sudo atk install -g <package manager> -a -C <dns provider>
sudo atk setup -r <web root> -h <hostname> -ac
```

For example, on Centos 7 using Google Cloud DNS with example.com:
```sh
sudo atk install -g yum -a -C dns-google
sudo atk setup -r ~/public -h example.com -ac
```

### License (MIT)

Copyright 2022 Dr. Vortex

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
