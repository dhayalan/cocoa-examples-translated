#! /usr/bin/env ruby
require 'osx/cocoa'

def explain(hash)
  puts "#{hash.to_ruby.inspect} has object_id #{hash.object_id}, ocid #{hash.__ocid__}."
end

array = [{'a' => 'A'}].to_ns
explain(array[0])
explain(array[0])
explain(array[0])

