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
        NSXAgentDesktopFilesMonitor::getAllObjects()
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
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        [
            {
                "uuid"        => uuid,
                "agentuid"    => NSXAgentDesktopFilesMonitor::agentuid(),
                "contentItem" => contentItem,
                "metric"      => 0.95,
                "commands"    => ["done"]
            }
        ]
    end

    # NSXAgentDesktopFilesMonitor::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "done" then
            # The only way to done this item is to clean the Desktop.
        end
    end
end
