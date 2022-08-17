
# encoding: UTF-8

class SystemEvents

    # SystemEvents::processEvent(event)
    def self.processEvent(event)

        #puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(bank account has been updated)" then
            Ax39forSections::processEvent(event)
        end

        if event["mikuType"] == "(object has been logically deleted)" then
            #
        end

        if event["mikuType"] == "(element has been done for today)" then
            Ax39forSections::processEvent(event)
        end

        if event["mikuType"] == "(change in ItemToGroupMapping for elements)" then
            ItemToGroupMapping::processEvent(event)
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
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder
        instanceId = Config::get("instanceId")
        LucilleCore::locationsAtFolder("#{Config::starlightCommLine()}/#{instanceId}")
            .each{|filepath1|
                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")

                if File.basename(filepath1)[-11, 11] != ".event.json" then
                    e = JSON.parse(IO.read(filepath1))
                    if verbose then
                        puts "SystemEvents::processCommLine: event: #{JSON.pretty_generate(e)}"
                    end
                    SystemEvents::processEvent(e)
                    FileUtils.rm(filepath1)
                end

                if File.basename(filepath1)[-8, 8] != ".sqlite3" then

                    if verbose then
                        puts "SystemEvents::processCommLine: DxPure file: #{File.basename(filepath1)}"
                    end

                    sha1 = Digest::SHA1.file(filepath1).hexdigest
                    if File.basename(filepath1) != "#{sha1}.sqlite3" then
                        puts "SystemEvents::processCommLine: DxPure file: #{File.basename(filepath1)}"
                        puts "The file has #{sha1}, which is an anomalie."
                        next
                    end

                    # We move the file to the BufferOut
                    filepath2 = DxPureFileManagement::bufferOutFilepath(sha1)
                    FileUtils.cp(filepath1, filepath2)

                    # and we copy it to XCache
                    DxPureFileManagement::dropDxPureFileInXCache(filepath1)

                    FileUtils.rm(filepath1)
                end
            }
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        Machines::theOtherInstanceIds().each{|targetInstanceId|
            e = event.clone
            # We technically no longer need to mark the instance with the recipient's id
            # because we are dropping the event in the right folder, but we keep it anyway.
            e["targetInstance"] = targetInstanceId
            filepath = "#{Config::starlightCommLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(e)) }
        }
    end

    # SystemEvents::processAndBroadcast(event)
    def self.processAndBroadcast(event)
        SystemEvents::processEvent(event)
        SystemEvents::broadcast(event)
    end
end
