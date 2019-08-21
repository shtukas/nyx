#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

=begin

Event
{
    "date"        => date,
    "description" => description,
    "weekday"     => $NSXAgentAnniversariesgetWeekdays[Date.parse(date).to_time.wday]
}

Anniversary 
{
    "original-date"    : <original date>
    "anniversary-date" : <anniversary date>
    "quantity"         : Integer
    "unit"             : "month"
}

ExtendedEvent
{
    "date": "2019-03-17",
    "description": "(Sunday) Corinne+Pascal begins. Euston Station (40 mins together waiting for her train to leave).",
    "weekday": "sunday",
    "anniversaries": [
        {
            "original-date": "2019-03-17",
            "anniversary-date": "2019-03-17",
            "quantity": 0,
            "unit": "month"
        },
        {
            "original-date": "2019-03-17",
            "anniversary-date": "2019-04-17",
            "quantity": 1,
            "unit": "month"
        },
        {
            "original-date": "2019-03-17",
            "anniversary-date": "2019-05-17",
            "quantity": 2,
            "unit": "month"
        }
    ]
}

=end

# anniversary [<original date>, <anniversary date>, <quantity>, <unit>]

$NSXAgentAnniversariesgetWeekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

class NSXAgentAnniversaries

    # NSXAgentAnniversaries::agentuuid()
    def self.agentuuid()
        "639beee6-c12e-4cb8-bc9a-f7890fa95db0"
    end

    # NSXAgentAnniversaries::getObjects()
    def self.getObjects()
        NSXAgentAnniversaries::getAllObjects()
    end

    def self.getEventLines()
        IO.read("/Galaxy/DataBank/anniversaries/anniversaries.txt")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 }
    end

    def self.anniversaryNext(anniversary)
        {
            "original-date"    => anniversary["original-date"],
            "anniversary-date" => Date.parse(anniversary["anniversary-date"]).next_month.to_s,
            "quantity"         => anniversary["quantity"]+1,
            "unit"             => anniversary["unit"]
        }
    end

    def self.anniversarySequenceLimited(anniversary, anniversaries = [])
        if anniversaries.size == 0 then
            anniversaries << anniversary.clone
        end
        nextanniversary = NSXAgentAnniversaries::anniversaryNext(anniversaries.last.clone)
        if nextanniversary["anniversary-date"] <= Time.new.to_s[0,10] then
            anniversaries << nextanniversary
            NSXAgentAnniversaries::anniversarySequenceLimited(anniversary, anniversaries)
        else
            anniversaries
        end
    end

    def self.dateToZerothMonthAnniversary(date)
        {
            "original-date"    => date,
            "anniversary-date" => date,
            "quantity"         => 0,
            "unit"             => "month"
        }
    end

    def self.updateEventObjectsWithAniversarySequence(object)
        zerothanniversary = NSXAgentAnniversaries::dateToZerothMonthAnniversary(object["date"])
        object["anniversaries"] = NSXAgentAnniversaries::anniversarySequenceLimited(zerothanniversary)
        object
    end

    def self.trueIfAnniversaryHasBeenProcessed(event, anniversary)
        KeyValueStore::flagIsTrue("/Galaxy/DataBank/anniversaries/kvstore-data", "b05b9dae-93d5-40f0-b68c-8cec95804b89:#{event["description"]}:#{JSON.generate(anniversary)}")
    end

    def self.getEventObjects()
        NSXAgentAnniversaries::getEventLines().map{|line|
            date = line[0,10]
            description = line[10,line.size].strip
            {
                "date" => date,
                "description" => description,
                "weekday" => $NSXAgentAnniversariesgetWeekdays[Date.parse(date).to_time.wday]
            }
        }
    end

    def self.getStructureNS1203()
        NSXAgentAnniversaries::getEventObjects()
            .map{|object|
                NSXAgentAnniversaries::updateEventObjectsWithAniversarySequence(object)
            }
    end

    # NSXAgentAnniversaries::getNs1203WithOutstandingSequenceElements()
    def self.getNs1203WithOutstandingSequenceElements()
        NSXAgentAnniversaries::getStructureNS1203().map{|ns1203|
            ns1203["anniversaries"] = ns1203["anniversaries"].select{|anniversary| !NSXAgentAnniversaries::trueIfAnniversaryHasBeenProcessed(ns1203, anniversary) }
            if ns1203["anniversaries"].size>0 then
                ns1203
            else
                nil
            end
        }
        .compact
    end

    def self.markAnniversaryAsProcessed(event, anniversary)
        KeyValueStore::setFlagTrue("/Galaxy/DataBank/anniversaries/kvstore-data", "b05b9dae-93d5-40f0-b68c-8cec95804b89:#{event["description"]}:#{JSON.generate(anniversary)}")
    end

    # NSXAgentAnniversaries::getAllObjects()
    def self.getAllObjects()
        return [] if NSXAgentAnniversaries::getNs1203WithOutstandingSequenceElements().empty?
        object = {
            "uuid"      => "eace4480-b93c-4b2f-bfb4-600f300812d3",
            "agentuid"  => NSXAgentAnniversaries::agentuuid(),
            "metric"    => 0.95,
            "announce"  => "anniversaries",
            "commands"  => ["process"],
            "defaultCommand" => "process"
        }
        [object]
    end

    # NSXAgentAnniversaries::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "process" then
            NSXAgentAnniversaries::getNs1203WithOutstandingSequenceElements().each{|ns1203|
                ns1203["anniversaries"].each{|anniversary|
                    puts ns1203["description"]
                    puts JSON.pretty_generate(anniversary)
                    LucilleCore::pressEnterToContinue()
                    NSXAgentAnniversaries::markAnniversaryAsProcessed(ns1203, anniversary)
                }
            }
        end
    end
end

