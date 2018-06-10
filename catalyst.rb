#!/usr/bin/ruby

# encoding: UTF-8

Dir.entries(File.dirname(__FILE__))
    .select{|filename| filename[-3 ,3]==".rb" }
    .each{|filename|
        require_relative filename
    }
