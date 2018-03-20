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

# -------------------------------------------------------------------------------------

PATH_TO_STREAM_FOLDER = "/Galaxy/DataBank/Catalyst/Stream"
METRIC_UUID = "eaa86995-7bc8-4263-9a39-784e9824b126"

# Stream::firstUpToSixItemsFolderpath()
# Stream::basemetric(uuid)
# Stream::pathToItemToCatalystObject(folderpath)
# Stream::getCatalystObjects()

class Stream

    def self.firstUpToSixItemsFolderpath()
        Dir.entries("#{PATH_TO_STREAM_FOLDER}/items")
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{PATH_TO_STREAM_FOLDER}/items/#{filename}" }
            .first(6)
    end
    
    def self.basemetric(uuid)
        metric = KeyValueStore::getOrNull(nil, "7d0d4344-57e3-4233-8764-96f4b182db69:#{uuid}")
        if metric.nil? then
            metric = 0.4 + 0.1*rand()
            KeyValueStore::set(nil, "7d0d4344-57e3-4233-8764-96f4b182db69:#{uuid}", metric)
            metric
        else
            metric.to_f
        end
    end

    def self.pathToItemToCatalystObject(folderpath)
        uuid = File.basename(folderpath)
        basemetric = Stream::basemetric(uuid)
        metric = 0.1 + DRbObject.new(nil, "druby://:10423").metric(uuid, 2, basemetric, 2) # 2 hours per week, base metric=1, run metric=2
        {
            "uuid" => uuid,
            "metric" => metric,
            "announce" => "(#{"%.3f" % metric}) stream: #{folderpath} (#{"%.2f" % ( DRbObject.new(nil, "druby://:10423").getEntityAdaptedTotalTimespan(uuid).to_f/3600 )} hours)",
            "commands" => ["start", "stop", "folder", "completed"],
            "default-commands" => DRbObject.new(nil, "druby://:10423").isRunning(uuid) ? ['stop'] : ['start'],
            "command-interpreter" => lambda{|object, command|  
                if command=='folder' then
                    system("open '#{object['item-folderpath']}'")
                    return
                end
                if command=='start' then
                    DRbObject.new(nil, "druby://:10423").start(uuid)
                    system("open '#{object['item-folderpath']}'")
                    return
                end
                if command=='stop' then
                    DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
                    return
                end
                if command=="completed" then
                    if DRbObject.new(nil, "druby://:10423").isRunning(object['uuid']) then
                        DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
                    end
                    timespan = DRbObject.new(nil, "druby://:10423").getEntityAdaptedTotalTimespan(uuid)
                    folderpaths = Stream::firstUpToSixItemsFolderpath()
                    if folderpaths.size>0 then
                        folderpaths.each{|xfolderpath| 
                            next if xfolderpath == object['item-folderpath']
                            xuuid = File.basename(xfolderpath)
                            xtimespan =  timespan.to_f/6
                            puts "Putting #{xtimespan} seconds for #{xuuid}"
                            DRbObject.new(nil, "druby://:10423").addTimeSpan(xuuid, xtimespan)
                        }
                    end
                    puts "Removing folder: #{object['item-folderpath']}"
                    LucilleCore::removeFileSystemLocation(object['item-folderpath'])
                    return
                end
            },
            "item-folderpath" => folderpath
        } 
    end

    def self.getCatalystObjects()

        # ---------------------------------------------------
        # DropOff 
        Dir.entries("#{PATH_TO_STREAM_FOLDER}/Stream-DropOff")
            .select{|filename| filename[0,1]!='.' }
            .map{|filename| "#{PATH_TO_STREAM_FOLDER}/Stream-DropOff/#{filename}" }
            .each{|filepath|  
                targetfolderpath = "#{PATH_TO_STREAM_FOLDER}/items/#{LucilleCore::timeStringL22()}"
                FileUtils.mkpath(targetfolderpath)
                LucilleCore::copyFileSystemLocation(filepath, targetfolderpath)
                LucilleCore::removeFileSystemLocation(filepath)
            }

        # ---------------------------------------------------
        # Catalyst Objects
        Stream::firstUpToSixItemsFolderpath()
            .map{|folderpath| Stream::pathToItemToCatalystObject(folderpath) }
    end
end
