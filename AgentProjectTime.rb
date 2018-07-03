#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'json'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "ProjectTime",
        "agent-uid"       => "3ae4a853-8ddd-438e-80a4-b078e030ca76",
        "general-upgrade" => lambda { ProjectTime::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| ProjectTime::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ ProjectTime::interface() }
    }
)

class ProjectTime

    def self.agentuuid()
        "3ae4a853-8ddd-438e-80a4-b078e030ca76"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        Dir.entries("/Galaxy/DataBank/Catalyst/Agents-Data/project-time")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "/Galaxy/DataBank/Catalyst/Agents-Data/project-time/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .map{|object|
                uuid = object["uuid"]
                projectuuid = object["project-uuid"]
                FKVStore::set("60407375-7e5d-4cfe-98fb-ecd34c0f2247:#{projectuuid}:#{Time.new.to_s[0, 13]}", "current") # We are marking that project has having a mini time commitment point for this hour 
                hours = object["commitment-in-hours"]
                doneTimeInSeconds = Chronos::summedTimespansInSecondsLiveValue(uuid)
                doneRatio = (doneTimeInSeconds.to_f/3600).to_f/hours
                object["agent-uid"] = self.agentuuid()
                object["announce"] = "mini time commitment #{hours} hours for project '#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}' [done: #{"%.2f" % (100*doneRatio)} %]"
                object["commands"] = ["start", "stop"]
                object["default-expression"] = Chronos::isRunning(uuid) ? "stop" : "start"
                object["is-running"] = Chronos::isRunning(uuid)
                object
            }
            .each{|object| TheFlock::addOrUpdateObject(object) }
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=='start' then
            Chronos::start(object["uuid"])
        end
        if command=='stop' then
            uuid = object["uuid"]
            hours = object["commitment-in-hours"]
            Chronos::stop(uuid)
            doneTimeInSeconds = Chronos::summedTimespansInSecondsLiveValue(uuid)
            if doneTimeInSeconds.to_f/3600 > hours then
                projectuuid = object["project-uuid"]
                Chronos::addTimeInSeconds(projectuuid, doneTimeInSeconds)
                FileUtils.rm("/Galaxy/DataBank/Catalyst/Agents-Data/project-time/#{uuid}.json")
            end
        end
    end
end
