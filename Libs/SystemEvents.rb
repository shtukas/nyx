
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        # puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            Lookup1::processEventInternally(event)
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            Fx18s::deleteObjectLogicallyNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEventInternally(event)
        end

        if event["mikuType"] == "Bank-records" then
            Bank::processEventInternally(event)
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEventInternally(event)
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneForToday::processEventInternally(event)
        end

        if event["mikuType"] == "NxDeleted" then
            Fx18s::deleteObjectLogicallyNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
        end

        if event["mikuType"] == "Fx18-records" then
            Fx18s::processEventInternally(event)
        end

        if event["mikuType"] == "ItemToGroupMapping" then
            ItemToGroupMapping::processEventInternally(event)
        end

        if event["mikuType"] == "ItemToGroupMapping-records" then
            ItemToGroupMapping::processEventInternally(event)
        end

        if event["mikuType"] == "NetworkLinks-records" then
            NetworkLinks::processEventInternally(event)
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|instanceName|
            e = event.clone
            e["targetInstance"] = instanceName
            filepath = "#{Config::starlightCommLine()}/#{CommonUtils::timeStringL22()}.event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(e)) }
        }
    end
end
