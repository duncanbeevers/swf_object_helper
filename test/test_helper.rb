$:.unshift(File.dirname(__FILE__) + '/../lib')

# Setup
require 'test/unit'
require 'rubygems'
require 'active_support'
require 'action_view'
require 'json'

require 'ruby-debug'
Debugger.settings[:autoeval] = true
Debugger.start

require File.join(File.dirname(__FILE__), '../init')
