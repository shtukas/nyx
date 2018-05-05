#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'drb/drb'

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "Commons.rb"

require 'colorize'

# -------------------------------------------------------------------------------------

# ReadingFiFOQueue::folderpaths(itemsfolderpath)
# ReadingFiFOQueue::getCatalystObjects()

class ReadingFiFOQueue
    def self.folderpaths(itemsfolderpath)
        Dir.entries(itemsfolderpath)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{itemsfolderpath}/#{filename}" }
    end
    def self.getCatalystObjects()
        folderpaths = ReadingFiFOQueue::folderpaths("/Galaxy/DataBank/Catalyst/ReadingFiFOQueue")
        if folderpaths.size==0 then
            []
        else
            [
                {
                    "uuid" => "9dade480",
                    "metric" => 1,
                    "announce" => "reading fifo queue",
                    "commands" => [],
                    "default-expression" => nil,
                    "command-interpreter" => lambda{|object, command|  },
                    "item-folderpath" => nil         
                }
            ]
        end

    end
end

# -------------------------------------------------------------------------------------

