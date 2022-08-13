
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        # puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            Lookup1::processEventInternally(event)
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            Fx18s::deleteObjectNoEvents(event["objectuuid"])
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
            Fx18s::deleteObjectNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
        end

        if event["mikuType"] == "Fx18s-allFiles-allRows" then
            Fx18s::processEventInternally(event)
        end

        if event["mikuType"] == "Fx18 File Event" then
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
        # "datablob" is no longer used in modern versions of Fx18
        #if event["mikuType"] == "Fx18 File Event" then
        #    if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
        #        event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData3_"])
        #    end
        #end
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|instanceName|
            e = event.clone
            e["targetInstance"] = instanceName
            filepath = "#{Config::starlightCommLine()}/#{CommonUtils::timeStringL22()}.event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(e)) }
        }
    end
end
