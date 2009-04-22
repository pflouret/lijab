#!/usr/bin/env ruby

require 'lijab/main'

trap("SIGINT") { Lijab::Main.quit }
Lijab::Main.run!
Thread.stop

