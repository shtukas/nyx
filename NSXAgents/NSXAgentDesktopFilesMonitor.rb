#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require 'drb/drb'

# -----------------------------------------------------------------

class NSXAgentDesktopFilesMonitor

    # NSXAgentDesktopFilesMonitor::agentuuid()
    def self.agentuuid()
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
        [
            {
                "uuid"               => "78558e33-68b0-4fc4-b7c5-b69192ea4f1c",
                "agentuid"           => "9fad55cf-3f41-45ae-b480-5cbef40ce57f",
                "metric"             => 0.95,
                "announce"           => "Seeing too many files on the Desktop",
                "commands"           => ["done"],
                "defaultCommand"  => "done",
                "service-port"       => 12350
            }
        ]
    end

    # NSXAgentDesktopFilesMonitor::processObjectAndCommand(object, command, isLocalCommand = true)
    def self.processObjectAndCommand(object, command, isLocalCommand = true)

    end
end
