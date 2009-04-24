#! /usr/bin/env ruby
require 'osx/cocoa'
include OSX

def run(klass, count)
  array = make_array(klass, count)
  first = collect_the_object_ids(array)
  second = collect_the_object_ids(array)
  if first == second
    puts "success"
  else
    puts "FAILURE for #{klass.name}"
    puts first[0,10].inspect
    puts second[0,10].inspect
  end
end

def make_array(klass, count)
  (0...count).collect { 
    klass.alloc.init
  }.to_ns
end

def collect_the_object_ids(array)
  array.collect { | e | e.object_id }.to_ruby
end


run(NSDictionary, 1)
run(NSString, 1)
run(NSTextField, 100000)

