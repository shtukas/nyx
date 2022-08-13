
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEvent(event)
    def self.processEvent(event)

        # puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            Lookup1::processEvent(event)
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            Fx18s::deleteObjectLogicallyNoEvents(event["objectuuid"])
            Lookup1::processEvent(event)
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEvent(event)
        end

        if event["mikuType"] == "Bank-records" then
            Bank::processEvent(event)
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEvent(event)
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneForToday::processEvent(event)
        end

        if event["mikuType"] == "NxDeleted" then
            Fx18s::deleteObjectLogicallyNoEvents(event["objectuuid"])
            Lookup1::processEvent(event)
        end

        if event["mikuType"] == "Fx18-records" then
            Fx18s::processEvent(event)
        end

        if event["mikuType"] == "ItemToGroupMapping" then
            ItemToGroupMapping::processEvent(event)
        end

        if event["mikuType"] == "ItemToGroupMapping-records" then
            ItemToGroupMapping::processEvent(event)
        end

        if event["mikuType"] == "NetworkLinks-records" then
            NetworkLinks::processEvent(event)
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
