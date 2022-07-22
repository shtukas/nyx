
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            filepath = Fx18Utils::computeLocalFx18Filepath(event["objectuuid"])
            return if !File.exists?(filepath) # object has been updated on one computer but has not yet been put on another
            Fx18Index1::updateIndexForFilepath(filepath)
        end

        if event["mikuType"] == "(object has been deleted)" then
            Fx18Utils::destroyLocalFx18NoEvent(event["objectuuid"])
            Fx18Index1::removeEntry(event["objectuuid"])
            Fx18DeletedFilesMemory::registerDeleted(event["objectuuid"])
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
            DoneToday::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxDeleted" then
            Fx18Utils::destroyLocalFx18NoEvent(event["objectuuid"])
            Fx18Utils::destroyLocalFx18NoEvent(event["objectuuid"])
            return
        end

        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData3_"])
            end
            objectuuid = event["objectuuid"]
            Fx18LocalObjectsDataWithInfinityHelp::ensureFileForPut(objectuuid)
            eventi = event["Fx18FileEvent"]
            Fx18Utils::commitEventToObjectuuidNoDrop(objectuuid, eventi["_eventuuid_"], eventi["_eventTime_"], eventi["_eventData1_"], eventi["_eventData2_"], eventi["_eventData3_"], eventi["_eventData4_"], eventi["_eventData5_"])
            return
        end
    end

    # SystemEvents::issueStargateDrop(event)
    def self.issueStargateDrop(event)
        if event["mikuType"] == "Fx18 File Event" then
            if event["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData3_"])
            end
        end

        instanceIds = ["Lucille20-pascal", "Lucille20-guardian", "Lucille18-pascal"] - [Config::get("instanceId")]

        instanceIds.each{|instanceId|
            filename = "#{CommonUtils::nx45()}.json"
            filepath = "/Volumes/Keybase (#{ENV['USER']})/private/0x107/Stargate-Drops2/#{instanceId}/#{filename}"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
            SystemEvents::fsckDrop(filepath)
        }
    end

    # SystemEvents::fsckDrop(filepath)
    def self.fsckDrop(filepath)
        # Date: July 21st, 2022
        # This function exists to test the datablobs drops, I think they are incorrects
        drop = JSON.parse(IO.read(filepath))
        if drop["mikuType"] == "Fx18 File Event" then
            if drop["Fx18FileEvent"]["_eventData1_"] == "datablob" then
                nhash1 = drop["Fx18FileEvent"]["_eventData2_"]
                blob = CommonUtils::base64_decode(drop["Fx18FileEvent"]["_eventData3_"])
                nhash2 = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
                if nhash1 != nhash2 then
                    # problem
                    puts "Huston, we have a problem!"
                    puts "filepath: #{filepath}"
                    puts "nhash1: #{nhash1}"
                    puts "nhash2: #{nhash2}"
                    puts "I am going to delete that file"
                    LucilleCore::pressEnterToContinue()
                end
            end
        end
    end

    # SystemEvents::pickupDrops()
    def self.pickupDrops()
        LucilleCore::locationsAtFolder("/Volumes/Keybase (#{ENV['USER']})/private/0x107/Stargate-Drops2/#{Config::get("instanceId")}")
            .each{|filepath|
                filename = File.basename(filepath)
                next if filename[0, 1] == "."
                next if filename[-5, 5] != ".json"
                puts "SystemEvents::pickupDrops(), file: #{filepath}"
                SystemEvents::fsckDrop(filepath)
                event = JSON.parse(IO.read(filepath))
                SystemEvents::processEventInternally(event)
                FileUtils.rm(filepath)
            }
    end
end
