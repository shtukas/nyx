#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

$ninja_packet = nil

class NSXAgentTheBridgeCLIs

    # NSXAgentTheBridgeCLIs::agentuuid()
    def self.agentuuid()
        "d2422ba0-88e9-4abb-9ab9-6d609015268f"
    end

    # NSXAgentTheBridgeCLIs::getAgentsFilepaths()
    def self.getAgentsFilepaths()
        IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/TheBridge/TheBridgeCLIsFilepaths.txt")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size>0 }
    end

    # NSXAgentTheBridgeCLIs::getObjects()
    def self.getObjects()
        NSXAgentTheBridgeCLIs::getAgentsFilepaths()
            .map{|filepath| 
                begin
                    JSON.parse(`#{filepath}`) 
                rescue
                    puts filepath
                    exit
                end
            }
            .flatten
    end

    # NSXAgentTheBridgeCLIs::getAllObjects()
    def self.getAllObjects()
        NSXAgentTheBridgeCLIs::getAgentsFilepaths()
            .map{|filepath| JSON.parse(`#{filepath}`) }
            .flatten
    end

    # NSXAgentTheBridgeCLIs::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        system("#{object["commandToShellInvocation"][command]}")
    end
end

