#!/usr/bin/ruby

# encoding: UTF-8
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'drb/drb'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'colorize'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"

# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "Stream",
        "agent-uid"       => "73290154-191f-49de-ab6a-5e5a85c6af3a",
        "general-upgrade" => lambda { AgentStream::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentStream::processObjectAndCommand(object, command) }
    }
)

# AgentStream::agentuuid()
# AgentStream::processObjectAndCommand(object, command)

# AgentStream::folderpaths(itemsfolderpath)
# AgentStream::folderpath2uuid(folderpath)
# AgentStream::getUUIDs()
# AgentStream::folderpathToCatalystObjectOrNull(folderpath)
# AgentStream::sendObjectToBinTimeline(object)
# AgentStream::objectCommandHandler(object, command)
# AgentStream::issueNewItemWithDescription(description)
# AgentStream::generalFlockUpgrade()

class AgentStream

    @@firstRun = true

    def self.agentuuid()
        "73290154-191f-49de-ab6a-5e5a85c6af3a"
    end
    
    def self.folderpaths(itemsfolderpath)
        Dir.entries(itemsfolderpath)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{itemsfolderpath}/#{filename}" }
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        return if !FKVStore::getOrNull("b6b96f14-3cb5-4182-8f1e-925d83d01e89:#{CommonsUtils::currentDay()}").nil?
        AgentStream::folderpaths(CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER)
            .first(1)
            .each{|folderpath1|
                folderpath2 = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                if !File.exists?(File.dirname(folderpath2)) then
                    FileUtils.mkpath File.dirname(folderpath2)
                end
                system("mv #{folderpath1} #{folderpath2}")
                uuid = SecureRandom.hex(4)
                File.open("#{folderpath2}/catalyst-uuid", 'w') {|f| f.write(uuid) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                AgentWave::writeScheduleToDisk(uuid, schedule)
            }
        FKVStore::set("b6b96f14-3cb5-4182-8f1e-925d83d01e89:#{CommonsUtils::currentDay()}", "done")
    end

    def self.processObjectAndCommand(object, command)

    end
end

# -------------------------------------------------------------------------------------