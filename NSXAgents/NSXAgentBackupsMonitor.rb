#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

$NSXAgentBackupsMonitorScriptnames = [ # Here we assume that they are all in the Backups-SubSystem folder
    "EnergyGrid-to-Venus",
    "Earth-to-Jupiter",
    "Saturn-to-Pluto"
]

$NSXAgentBackupsMonitorScriptnamesToPeriodInDays = {
    "EnergyGrid-to-Venus" => 7,
    "Earth-to-Jupiter" => 8,
    "Saturn-to-Pluto" => 10
}


class NSXAgentBackupsMonitor

    # NSXAgentBackupsMonitor::agentuid()
    def self.agentuid()
        "63027c23-6131-4230-b49b-d3f23aa5ff54"
    end

    def self.scriptNameToLastUnixtime(sname)
        filename = "#{DATABANK_FOLDER_PATH}/Backups/Logs/#{sname}.log"
        IO.read(filename).to_i
    end

    def self.scriptNameToNextOperationUnixtime(scriptname)
        NSXAgentBackupsMonitor::scriptNameToLastUnixtime(scriptname) + $NSXAgentBackupsMonitorScriptnamesToPeriodInDays[scriptname]*86400
    end

    def self.scriptNameToIsDueFlag(scriptname)
        Time.new.to_i > NSXAgentBackupsMonitor::scriptNameToNextOperationUnixtime(scriptname)
    end

    def self.scriptNameToCatalystObjectOrNull(scriptname)
        return nil if !NSXAgentBackupsMonitor::scriptNameToIsDueFlag(scriptname)
        uuid = Digest::SHA1.hexdigest("60507ff5-adce-4444-9e57-c533efb01136:#{scriptname}")
        announce = "[Backups Monitor] /Galaxy/LucilleOS/Backups-SubSystem/#{scriptname}"
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        {
            "uuid"         => uuid,
            "agentuid"     => NSXAgentBackupsMonitor::agentuid(),
            "contentItem"  => contentItem,
            "metric"       => 0.53,
            "commands"     => ["done"],
            "service-port" => 12345
        }
    end

    # NSXAgentBackupsMonitor::getObjects()
    def self.getObjects()
        NSXAgentBackupsMonitor::getAllObjects()
    end

    # NSXAgentBackupsMonitor::getAllObjects()
    def self.getAllObjects()
        $NSXAgentBackupsMonitorScriptnames
            .map{|scriptname|
                NSXAgentBackupsMonitor::scriptNameToCatalystObjectOrNull(scriptname)
            }
            .compact
    end

    # NSXAgentBackupsMonitor::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentBackupsMonitor::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXAgentBackupsMonitor::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "open" then
            return
        end
        if command == "done" then
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentBackupsMonitor",
            "agentuid"    => NSXAgentBackupsMonitor::agentuid(),
        }
    )
rescue
end
