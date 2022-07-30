
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        # puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            Lookup1::processEventInternally(event)
            return
        end

        if event["mikuType"] == "(object has been deleted)" then
            Fx18::deleteObjectNoEvents(event["objectuuid"])
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
            Fx18::deleteObjectNoEvents(event["objectuuid"])
            return
        end

        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData3_"])
            end
            objectuuid = event["objectuuid"]
            eventi = event["Fx18FileEvent"]
            Fx18::commit(objectuuid, eventi["_eventuuid_"], eventi["_eventTime_"], eventi["_eventData1_"], eventi["_eventData2_"], eventi["_eventData3_"], eventi["_eventData4_"], eventi["_eventData5_"])
            return
        end
    end

    # SystemEvents::issueStargateDrop(event)
    def self.issueStargateDrop(event)
        Machines::foldernamesForStargateDrop().each{|foldername|
            filepath = "/Users/#{ENV["USER"]}/Galaxy/DataBank/Stargate/bitbucket/stargate1/#{foldername}/#{CommonUtils::timeStringL22()}.event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        }
    end

    # SystemEvents::pickupDrops()
    def self.pickupDrops()
        folderpath = "/Users/#{ENV["USER"]}/Galaxy/DataBank/Stargate/bitbucket/stargate1/#{Config::get("instanceId")}"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath)[-11, 11] == ".event.json"}
            .each{|filepath|
                event = JSON.parse(IO.read(filepath))
                puts "SystemEvents::pickupDrops(): #{JSON.pretty_generate(event)}"
                SystemEvents::processEventInternally(event)
                FileUtils.rm(filepath)
            }
    end
end
