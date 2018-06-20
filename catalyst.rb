#!/usr/bin/ruby

# encoding: UTF-8

Dir.entries(File.dirname(__FILE__))
    .select{|filename| filename[-3 ,3]==".rb" }
    .select{|filename| !filename.include?("sync-conflict") }
    .each{|filename|
        require_relative filename
    }
