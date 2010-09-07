require 'rubygems'
require 'twisaurus'
require 'daemons'

Daemons.run('twisaurus.rb', {:monitor => true})