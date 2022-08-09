
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        # puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            Fx18s::deleteObjectNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEventInternally(event)
            return
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneForToday::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxDeleted" then
            Fx18s::deleteObjectNoEvents(event["objectuuid"])
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData3_"])
            end
            eventi = event["Fx18FileEvent"]
            Fx18s::commit(eventi["_objectuuid_"], eventi["_eventuuid_"], eventi["_eventTime_"], eventi["_eventData1_"], eventi["_eventData2_"], eventi["_eventData3_"], eventi["_eventData4_"], eventi["_eventData5_"])
            Lookup1::reconstructEntry(eventi["_objectuuid_"])
            return
        end

        if event["mikuType"] == "Daily Slots: Unregister" then
            DailySlots::internalEventProcessing(event)
        end

        if event["mikuType"] == "Daily Slots: Register" then
            DailySlots::internalEventProcessing(event)
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData3_"])
            end
        end
        puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|instanceName|
            e = event.clone
            e["targetInstance"] = instanceName
            Mercury2::put("d054a16c-3d68-43b2-b49d-412ea5f5d0af", e)
        }
    end
end
