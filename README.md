lijab
====

A line oriented extensible jabber client.

http://palbo.github.com/lijab


Disclaimer
----------

This program carries a big Works For Me™ sign, and is tested in very little
configurations, so messages may be lost, misrouted, eaten, etc.

Use at your own risk! :-)


Features
--------

* Tab completion for most things.
* Shiny colors!
* Logging.
* Roster / subscriptions handling.
* Status / priority handling.
* Delivery and display of chat state notifications.
* Hooks (on_message_received, on_message_sent, et al).
* Fairly easy to make new commands in ruby.
* Command aliases


Requirements
------------

* GNU Readline (pretty sure libedit won't work right now).
* A very ansi-compatible terminal, color is probably a good idea.

### Gems
* xmpp4r
* file-tail
* term-ansicolor

### Debian/Ubuntu

    $ sudo apt-get install ruby1.8-dev rubygems1.8 libreadline-dev libopenssl-ruby


Installation
------------

    $ sudo gem install palbo-lijab -s http://gems.github.com

### Debian/Ubuntu

Also need to do
    
    $ sudo ln -s /var/lib/gems/1.8/bin/lijab /usr/bin/lijab 

Or put the gems bin dir in your path (e.g. in your .bashrc)

    PATH=$PATH:/var/lib/gems/1.8/bin

Go complain to them, https://bugs.launchpad.net/ubuntu/+source/libgems-ruby/+bug/145267


Known issues
------------

Usually reconnection works well-ish, but sometimes lijab doesn't realize the
connection died so you might have to restart the program.


Bugs
----

I make and unconscious effort to introduce bugs in all my programs, so people
have something to entertain themselves with.

Report bugs in http://palbo.github.com/lijab/issues, github pull request for patches.

Comments, bug reports and patches can also go to `quuxbaz@gmail.com`.


License
-------

    Copyright (c) 2009 Pablo Flouret <quuxbaz@gmail.com>
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met: Redistributions of
    source code must retain the above copyright notice, this list of conditions and
    the following disclaimer. Redistributions in binary form must reproduce the
    above copyright notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the distribution.
    Neither the name of the software nor the names of its contributors may be
    used to endorse or promote products derived from this software without specific
    prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See the LICENSE file for more details.


