require 'rubygems'
require 'test/unit'
require 'contest'
require 'mocha'
require 'json'
require File.join(File.dirname(__FILE__), '..', 'twisaurus')
require File.join(File.dirname(__FILE__), '..', 'thesaurus')

def fixture_file(filename)
  return "" if filename == ""
  file_path = File.expand_path(File.dirname(__FILE__) + "/fixtures/" + "#{filename}.json")
  return JSON.parse(File.read(file_path))
end