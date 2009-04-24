#! /usr/bin/env ruby
require 'osx/cocoa'

def explain(thing)
  puts "#{thing.to_ruby.inspect} has object_id #{thing.object_id}, ocid #{thing.__ocid__}."
end

array = [{'a' => 'A'}].to_ns
explain(array[0])
explain(array[0])
explain(array[0])

array = ["a"].to_ns
explain(array[0])
explain(array[0])
explain(array[0])


array = [OSX::NSButton.alloc.init]
explain(array[0])
explain(array[0])
explain(array[0])
