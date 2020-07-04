
# encoding: UTF-8
require 'json'

require_relative "Common.rb"

# -------------------------------------------------------------------------------------

=begin

Event
{
    "date"        => date,
    "description" => description,
    "weekday"     => Anniversaries::weekdays()[Date.parse(date).to_time.wday]
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

class Anniversaries

    # Anniversaries::weekdays()
    def self.weekdays()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    end

    def self.getEventLines()
        IO.read("#{CatalystCommon::catalystDataCenterFolderpath()}/Anniversaries/anniversaries.txt")
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
        nextanniversary = Anniversaries::anniversaryNext(anniversaries.last.clone)
        if nextanniversary["anniversary-date"] <= Time.new.to_s[0,10] then
            anniversaries << nextanniversary
            Anniversaries::anniversarySequenceLimited(anniversary, anniversaries)
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
        zerothanniversary = Anniversaries::dateToZerothMonthAnniversary(object["date"])
        object["anniversaries"] = Anniversaries::anniversarySequenceLimited(zerothanniversary)
        object
    end

    def self.trueIfAnniversaryHasBeenProcessed(event, anniversary)
        KeyValueStore::flagIsTrue("#{CatalystCommon::catalystDataCenterFolderpath()}/Anniversaries/kvstore-data", "b05b9dae-93d5-40f0-b68c-8cec95804b89:#{event["description"]}:#{JSON.generate(anniversary)}")
    end

    def self.getEventObjects()
        Anniversaries::getEventLines().map{|line|
            date = line[0,10]
            description = line[10,line.size].strip
            {
                "date" => date,
                "description" => description,
                "weekday" => Anniversaries::weekdays()[Date.parse(date).to_time.wday]
            }
        }
    end

    def self.getStructureNS1203()
        Anniversaries::getEventObjects()
            .map{|object|
                Anniversaries::updateEventObjectsWithAniversarySequence(object)
            }
    end

    # Anniversaries::getNs1203WithOutstandingSequenceElements()
    def self.getNs1203WithOutstandingSequenceElements()
        Anniversaries::getStructureNS1203().map{|ns1203|
            ns1203["anniversaries"] = ns1203["anniversaries"].select{|anniversary| !Anniversaries::trueIfAnniversaryHasBeenProcessed(ns1203, anniversary) }
            if ns1203["anniversaries"].size>0 then
                ns1203
            else
                nil
            end
        }
        .compact
    end

    # Anniversaries::markAnniversaryAsProcessed(event, anniversary)
    def self.markAnniversaryAsProcessed(event, anniversary)
        KeyValueStore::setFlagTrue("#{CatalystCommon::catalystDataCenterFolderpath()}/Anniversaries/kvstore-data", "b05b9dae-93d5-40f0-b68c-8cec95804b89:#{event["description"]}:#{JSON.generate(anniversary)}")
    end

    # Anniversaries::catalystObjects()
    def self.catalystObjects()
        if Anniversaries::getNs1203WithOutstandingSequenceElements().empty? then
            []
        else
            [
                {
                    "uuid"           => "eace4480-b93c-4b2f-bfb4-600f300812d3",
                    "body"           => "anniversaries",
                    "metric"         => 0.95,
                    "commands"       => [],
                    "execute" => lambda { |input|
                        Anniversaries::getNs1203WithOutstandingSequenceElements().each{|ns1203|
                            ns1203["anniversaries"].each{|anniversary|
                                puts ns1203["description"]
                                puts JSON.pretty_generate(anniversary)
                                LucilleCore::pressEnterToContinue()
                                Anniversaries::markAnniversaryAsProcessed(ns1203, anniversary)
                            }
                        }
                    },
                    "x-anniversaries" => true
                }
            ]
        end
    end

end
