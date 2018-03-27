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

# -------------------------------------------------------------------------------------

TORR_PATH_TO_STREAM_ITEM_FOLDER = "/Galaxy/DataBank/Catalyst/Stream/items"
TORR_PATH_TO_TORR_ITEM_FOLDER = "/Galaxy/DataBank/Catalyst/Torr/items"

# Torr::itemsFolderpath()
# Torr::getItemDescription(folderpath)
# Torr::pathToItemToCatalystObject(folderpath)
# Torr::objectCommandHandler(object, command)
# Torr::getCatalystObjects()

class Torr

    def self.itemsFolderpath()
        f1 = Dir.entries(TORR_PATH_TO_STREAM_ITEM_FOLDER)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{TORR_PATH_TO_STREAM_ITEM_FOLDER}/#{filename}" }
            .select{|folderpath| File.exist?("#{folderpath}/.torr") }
        f2 = Dir.entries(TORR_PATH_TO_TORR_ITEM_FOLDER)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{TORR_PATH_TO_TORR_ITEM_FOLDER}/#{filename}" }
        f1+f2
    end

    def self.getItemDescription(folderpath)
        uuid = IO.read("#{folderpath}/.uuid").strip
        description = KeyValueStore::getOrDefaultValue(nil, "c441a43a-bb70-4850-b23c-1db5f5665c9a:#{uuid}", "#{folderpath}")
    end
    def self.uuid2metricuuid(uuid)
        "#{uuid}:#{Today.new.to_s[0,10]}"
    end
    def self.pathToItemToCatalystObject(folderpath, individualItemDailyCommitmentInHours)
        if !File.exist?("#{folderpath}/.uuid") then
            File.open("#{folderpath}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
        end
        uuid = IO.read("#{folderpath}/.uuid").strip
        description = Torr::getItemDescription(folderpath)
        metric = DRbObject.new(nil, "druby://:10423").metric2(Torr::uuid2metricuuid(uuid), 1, individualItemDailyCommitmentInHours, 0.6, 0.7, 2)
        {
            "uuid" => uuid,
            "metric" => metric,
            "announce" => "(#{"%.3f" % metric}) torr: #{description} (#{"%.2f" % ( DRbObject.new(nil, "druby://:10423").getEntityTotalTimespanForPeriod(Torr::uuid2metricuuid(uuid), 7).to_f/3600 )} hours)",
            "commands" => ["start", "stop", "folder", "set-description", "completed"],
            "default-commands" => DRbObject.new(nil, "druby://:10423").isRunning(Torr::uuid2metricuuid(uuid)) ? ['stop'] : ['start'],
            "command-interpreter" => lambda{|object, command| Torr::objectCommandHandler(object, command) },
            "item-folderpath" => folderpath
        }
    end

    def self.objectCommandHandler(object, command)
        if command=='folder' then
            system("open '#{object['item-folderpath']}'")
            return
        end
        if command=='start' then
            uuid = object['uuid']
            DRbObject.new(nil, "druby://:10423").start(Torr::uuid2metricuuid(uuid))
            system("open '#{object['item-folderpath']}'")
            return
        end
        if command=='stop' then
            uuid = object['uuid']
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(Torr::uuid2metricuuid(uuid))
            return
        end
        if command=='set-description' then
            uuid = object['uuid']
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            KeyValueStore::set(nil, "c441a43a-bb70-4850-b23c-1db5f5665c9a:#{uuid}", "#{description}")
            return
        end
        if command=="completed" then
            uuid = object['uuid']
            if DRbObject.new(nil, "druby://:10423").isRunning(Torr::uuid2metricuuid(uuid)) then
                DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(Torr::uuid2metricuuid(uuid))
            end
            time = Time.new
            targetFolder = "/Galaxy/DataBank/Catalyst/ArchivesTimeline/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
            puts "Source: #{object['item-folderpath']}"
            puts "Target: #{targetFolder}"
            FileUtils.mkpath(targetFolder)
            FileUtils.mv("#{object['item-folderpath']}",targetFolder)
            LucilleCore::removeFileSystemLocation(object['item-folderpath'])
            return
        end
    end

    def self.getCatalystObjects()
        return [] if Torr::itemsFolderpath().size==0
        Torr::itemsFolderpath()
            .map{|folderpath| Torr::pathToItemToCatalystObject(folderpath, 4.to_f/Torr::itemsFolderpath().size) }
    end
end
