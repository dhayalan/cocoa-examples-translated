#! /usr/bin/env ruby
require 'osx/cocoa'
include OSX

def run
  array = do_something_that_yields_an_array
  puts array.class

  puts "== Annotating and checking:"
  array.each do | thing | 
    def thing.hi!; puts "hi from #{self.class}!"; end
    explain(thing)
    thing.hi!
  end

  GC.start
  puts "== Using:"
  array.each do | thing |
    explain(thing)
    thing.hi!
  end
end

def do_something_that_yields_an_array
#  return ["1", "2", "3"].to_ns
  (1..50).collect { | name | NSTextField.alloc.init }.to_ns
end


def explain(thing)
  puts "#{thing} has object_id #{thing.object_id}, ocid #{thing.__ocid__}."
end

run
