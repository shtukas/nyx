#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require 'drb/drb'

# -----------------------------------------------------------------

class NSXAgentDesktopFilesMonitor

    # NSXAgentDesktopFilesMonitor::agentuid()
    def self.agentuid()
        "ec12c56b-9692-424e-bb17-220b9066407d"
    end

    # NSXAgentDesktopFilesMonitor::getObjects()
    def self.getObjects()
        []
    end

    # NSXAgentDesktopFilesMonitor::shouldAlert()
    def self.shouldAlert()
        Dir.entries("/Users/pascal/Desktop").size > 10
    end

    # NSXAgentDesktopFilesMonitor::getAllObjects()
    def self.getAllObjects()
        return [] if !NSXAgentDesktopFilesMonitor::shouldAlert()
        uuid = "78558e33-68b0-4fc4-b7c5-b69192ea4f1c"
        announce = "Seeing too many files on the Desktop"
        contentStoreItem = {
            "type" => "line",
            "line" => announce
        }
        NSXContentStore::setItem(uuid, contentStoreItem)
        scheduleStoreItem = {
            "type" => "todo-and-inform-agent-11b30518"
        }
        NSXScheduleStore::setItem(uuid, scheduleStoreItem)
        [
            {
                "uuid"               => uuid,
                "agentuid"           => NSXAgentDesktopFilesMonitor::agentuid(),
                "metric"             => 0.95,
                "contentStoreItemId"  => uuid,
                "scheduleStoreItemId" => uuid,
                "defaultCommand"  => "done",
                "service-port"       => 12350
            }
        ]
    end

    def self.getCommands()
        []
    end

    # NSXAgentDesktopFilesMonitor::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)

    end
end
