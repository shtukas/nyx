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

# -------------------------------------------------------------------------------------

PATH_TO_QUEUE_FOLDER = "/Galaxy/DataBank/Catalyst/Queue"
METRIC_UUID = "eaa86995-7bc8-4263-9a39-784e9824b126"

class Queue
    # Queue::getCatalystObjects()
    def self.getCatalystObjects()

        Dir.entries("#{PATH_TO_QUEUE_FOLDER}/Queue-DropOff")
            .select{|filename| filename[0,1]!='.' }
            .map{|filename| "#{PATH_TO_QUEUE_FOLDER}/Queue-DropOff/#{filename}" }
            .each{|filepath|  
                targetfolderpath = "#{PATH_TO_QUEUE_FOLDER}/items/#{LucilleCore::timeStringL22()}"
                FileUtils.mkpath(targetfolderpath)
                LucilleCore::copyFileSystemLocation(filepath, targetfolderpath)
                LucilleCore::removeFileSystemLocation(filepath)
            }

        objects = []
        metric = DRbObject.new(nil, "druby://:10423").metric(METRIC_UUID, 4, 1, 2)
        objects << {
            "uuid" => "f8418a41-cd0f-4193-b0b2-f3190b4eae0a",
            "metric" => metric,
            "announce" => "(#{"%.3f" % metric}) queue",
            "commands" => ["start", "stop", "folder"],
            "default-commands" => [],
            "command-interpreter" => lambda{|object, command|  
                if command=='folder' then
                    system("open '/Galaxy/DataBank/Catalyst/Queue/current-item'")
                    return
                end
                if command=='start' then
                    DRbObject.new(nil, "druby://:10423").start(METRIC_UUID)
                    return
                end
                if command=='stop' then
                    DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(METRIC_UUID)
                    return
                end
            }
        } 
        objects
    end
end
