#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

$ninja_packet = nil

class NSXAgentNinja

    # NSXAgentNinja::agentuuid()
    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    # NSXAgentNinja::getImpactsForDisk()
    def self.getImpactsForDisk()
        JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/Ninja/impacts.json"))
    end

    # NSXAgentNinja::issueImpact()
    def self.issueImpact()
        impacts = NSXAgentNinja::getImpactsForDisk()
        impacts << Time.new.to_i
        File.open("/Galaxy/DataBank/Catalyst/Agents-Data/Ninja/impacts.json", "w"){|f| f.puts(JSON.generate(impacts)) }
    end

    # NSXAgentNinja::impactMetricCoefficient()
    def self.impactMetricCoefficient()
        impacts = NSXAgentNinja::getImpactsForDisk().reject{|impact| (Time.new.to_i - impact) > 86400 }
        return 1 if impacts.size==0
        1 - impacts.map{|unixtime| 0.1*Math.exp(-(Time.new.to_i - unixtime).to_f/3600) }.inject(0, :+)
    end

    # NSXAgentNinja::impactsGarbageCollection()
    def self.impactsGarbageCollection()
        impacts = NSXAgentNinja::getImpactsForDisk().reject{|impact| (Time.new.to_i - impact) > 86400 }
        File.open("/Galaxy/DataBank/Catalyst/Agents-Data/Ninja/impacts.json", "w"){|f| f.puts(JSON.generate(impacts)) }
    end

    def self.getObjects()
        if $ninja_packet.nil? then
            $ninja_packet = JSON.parse(`ninja api:next-folderpath-or-null`)[0]
        end
        return [] if $ninja_packet.nil?
        object = {
            "uuid"      => "96287511",
            "agentUID"  => self.agentuuid(),
            "metric"    => 0.19 + NSXAgentNinja::impactMetricCoefficient()*0.6*$ninja_packet["metric"], # The metric given by ninja is between 0 and 1
            "announce"  => "ninja: folderpath: #{$ninja_packet["folderpath"]}",
            "commands"  => [],
            "defaultExpression" => "play",
            "item-data" => {
                "ninja-folderpath" => $ninja_packet["folderpath"]
            }
        }
        [object]
    end

    def self.processObjectAndCommand(object, command)
        if command == "play" then
            folderpath = object["item-data"]["ninja-folderpath"]
            system("ninja api:play-folderpath '#{folderpath}'")
            $ninja_packet = nil
            NSXAgentNinja::issueImpact()
        end
    end

    def self.interface()
        puts "Impact Metric Coefficient: #{NSXAgentNinja::impactMetricCoefficient()}"
        LucilleCore::pressEnterToContinue()
    end

end

NSXAgentNinja::impactsGarbageCollection()

