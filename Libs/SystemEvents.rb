
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEvent(event)
    def self.processEvent(event)

        #puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(bank account has been updated)" then
            Ax39forSections::processEvent(event)
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            Fx256::deleteObjectLogicallyNoEvents(event["objectuuid"])
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
            Fx256::deleteObjectLogicallyNoEvents(event["objectuuid"])
        end

        if event["mikuType"] == "Fx18-records" then
            Fx256::processEvent(event)
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

    # SystemEvents::processCommLine(verbose)
    def self.processCommLine(verbose)
        LucilleCore::locationsAtFolder(Config::starlightCommLine())
            .each{|filepath|
                next if !File.exists?(filepath)
                next if File.basename(filepath).start_with?(".")
                next if File.basename(filepath)[-11, 11] != ".event.json"
                e = JSON.parse(IO.read(filepath))
                next if e["targetInstance"] != Config::get("instanceId")
                if verbose then
                    puts "SystemEvents::processCommLine: #{JSON.pretty_generate(e)}"
                end
                SystemEvents::processEvent(e)
                FileUtils.rm(filepath)
            }
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

    # SystemEvents::processAndBroadcast(event)
    def self.processAndBroadcast(event)
        SystemEvents::processEvent(event)
        SystemEvents::broadcast(event)
    end
end
