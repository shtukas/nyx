
# encoding: UTF-8

class SystemEvents

    # SystemEvents::process(event)
    def self.process(event)

        #puts "SystemEvent(#{JSON.pretty_generate(event)})"

        # ordering: as they come

        if event["mikuType"] == "(bank account has been updated)" then
            Ax39Extensions::processEvent(event)
        end

        if event["mikuType"] == "(element has been done for today)" then
            Ax39Extensions::processEvent(event)
        end

        if event["mikuType"] == "(do not show until has been updated)" then
            Ax39Extensions::processEvent(event)
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEvent(event)
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEvent(event)
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneForToday::processEvent(event)
        end

        if event["mikuType"] == "NxDeleted" then
            objectuuid = event["objectuuid"]
            NxDeleted::deleteObjectNoEvents(objectuuid)
        end

        if event["mikuType"] == "AttributeUpdate" then
            objectuuid = event["objectuuid"]
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"]
            attname    = event["attname"]
            attvalue   = event["attvalue"]
            ItemsEventsLog::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
            begin
                # This cane fail when we are using a new program, which doesn't expect old mikuTypes 
                # (for instance generic-description is failing)
                # on data that is still old.
                Items::updateIndexAtObjectAttempt(objectuuid)
            rescue
            end
        end

        if event["mikuType"] == "XCacheSet" then
            key = event["key"]
            value = event["value"]
            XCache::set(key, value)
        end

        if event["mikuType"] == "XCacheFlag" then
            key = event["key"]
            flag = event["flag"]
            XCache::setFlag(key, flag)
        end

        if event["mikuType"] == "TimeCommitmentMapping" then
            TimeCommitmentMapping::processEvent(event)
        end

        if event["mikuType"] == "NetworkLinks" then
            NetworkLinks::processEvent(event)
        end

        if event["mikuType"] == "NetworkArrows" then
            NetworkArrows::processEvent(event)
        end

        if event["mikuType"] == "AttributeUpdate.v2" then
            objectuuid = event["objectuuid"]
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"]
            attname    = event["attname"]
            attvalue   = event["attvalue"]
            ItemsEventsLog::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
            begin
                # This cane fail when we are using a new program, which doesn't expect old mikuTypes 
                # (for instance generic-description is failing)
                # on data that is still old.
                Items::updateIndexAtObjectAttempt(objectuuid)
            rescue
            end
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        SystemEvents::writeEventToOutBuffer(event)
    end

    # SystemEvents::sendTo(event, targetInstanceId)
    def self.sendTo(event, targetInstanceId)
        filepath = "#{Config::starlightCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.event.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end

    # SystemEvents::processAndBroadcast(event)
    def self.processAndBroadcast(event)
        SystemEvents::process(event)
        SystemEvents::broadcast(event)
    end

    # SystemEvents::processCommsLine(verbose)
    def self.processCommsLine(verbose)
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder

        updatedObjectuuids = []

        instanceId = Config::get("instanceId")
        LucilleCore::locationsAtFolder("#{Config::starlightCommsLine()}/#{instanceId}")
            .each{|filepath1|
                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")

                if File.basename(filepath1).include?(".owner-mapping.sqlite3") then
                    FileUtils.rm(filepath1)
                    next
                end

                if File.basename(filepath1)[-11, 11] == ".event.json" then
                    e = JSON.parse(IO.read(filepath1))
                    if verbose then
                        puts "SystemEvents::processCommsLine: event: #{JSON.pretty_generate(e)}"
                    end
                    SystemEvents::process(e)
                    FileUtils.rm(filepath1)
                    next
                end

                if File.basename(filepath1)[-28, 28] == ".owner-items-mapping.sqlite3" then
                    if verbose then
                        puts "SystemEvents::processCommsLine: reading: #{File.basename(filepath1)}"
                    end

                    knowneventuuids = TimeCommitmentMapping::eventuuids()

                    db1 = SQLite3::Database.new(filepath1)
                    db1.busy_timeout = 117
                    db1.busy_handler { |count| true }
                    db1.results_as_hash = true
                    db1.execute("select * from _mapping_", []) do |row|
                        next if knowneventuuids.include?(row["_eventuuid_"])
                        puts "owner-items-mapping: importing event: #{row["_eventuuid_"]}"
                        eventuuid = row["_eventuuid_"]
                        eventTime = row["_eventTime_"]
                        owneruuid = row["_owneruuid_"]
                        itemuuid  = row["_itemuuid_"]
                        operationType = row["_operationType_"]
                        ordinal   = row["_ordinal_"]
                        TimeCommitmentMapping::linkNoEvents(eventuuid, eventTime, owneruuid, itemuuid, operationType, ordinal)
                    end
                    db1.close

                    FileUtils.rm(filepath1)
                    next
                end

                if CommonUtils::ends_with?(File.basename(filepath1), "items-events-log.sqlite3") then
                    if verbose then
                        puts "SystemEvents::processCommsLine: reading: items-events-log.sqlite3"
                    end
                    db1 = SQLite3::Database.new(filepath1)
                    db1.busy_timeout = 117
                    db1.busy_handler { |count| true }
                    db1.results_as_hash = true
                    db1.execute("select * from _events_", []) do |row|
                        objectuuid = row["_objectuuid_"]
                        eventuuid  = row["_eventuuid_"]
                        eventTime  = row["_eventTime_"]
                        attname    = row["_attname_"]
                        attvalue   = JSON.parse(row["_attvalue_"])
                        next if ItemsEventsLog::eventExistsAtItemsEventsLog(eventuuid)
                        puts "reading from a items-events-log.sqlite3 that came on the commsline: event: #{eventuuid}"
                        ItemsEventsLog::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
                    end
                    db1.close
                    FileUtils.rm(filepath1)
                    Items::syncWithEventLog(true)
                    next
                end

                if File.basename(filepath1)[-13, 13] == ".bank.sqlite3" then
                    if verbose then
                        puts "SystemEvents::processCommsLine: reading: #{File.basename(filepath1)}"
                    end

                    knowneventuuids = Bank::eventuuids()

                    db1 = SQLite3::Database.new(filepath1)
                    db1.busy_timeout = 117
                    db1.busy_handler { |count| true }
                    db1.results_as_hash = true
                    db1.execute("select * from _bank_", []) do |row|
                        next if knowneventuuids.include?(row["_eventuuid_"])
                        puts "bank: importing row: #{JSON.pretty_generate(row)}"
                        Bank::insertRecord(row)
                    end
                    db1.close

                    FileUtils.rm(filepath1)
                    next
                end

                if File.basename(filepath1)[-22, 22] == ".network-links.sqlite3" then
                    if verbose then
                        puts "SystemEvents::processCommsLine: reading: #{File.basename(filepath1)}"
                    end

                    knowneventuuids = NetworkLinks::eventuuids()

                    db1 = SQLite3::Database.new(filepath1)
                    db1.busy_timeout = 117
                    db1.busy_handler { |count| true }
                    db1.results_as_hash = true
                    db1.execute("select * from _links_", []) do |row|
                        next if knowneventuuids.include?(row["_eventuuid_"])
                        puts "network links: importing row: #{JSON.pretty_generate(row)}"
                        NetworkLinks::insertRow(row)
                    end
                    db1.close

                    FileUtils.rm(filepath1)
                    next
                end

                if CommonUtils::ends_with?(filepath1, ".system-events.jsonlines") then

                    if verbose then
                        puts "SystemEvents::processCommsLine: reading: #{File.basename(filepath1)}"
                    end

                    IO.read(filepath1)
                        .lines
                        .each{|line|
                            data = line.strip
                            next if data == ""
                            event = JSON.parse(data)
                            if verbose then
                                puts "event from system events: #{JSON.pretty_generate(event)}"
                            end
                            SystemEvents::process(event)
                        }

                    FileUtils.rm(filepath1)
                    next
                end

                if CommonUtils::ends_with?(filepath1, ".file-datastore1") then
                    DataStore1::putDataByFilepathNoCommLine(filepath1)
                    FileUtils.rm(filepath1)
                    next
                end

                raise "(error: 600967d9-e9d4-4612-bf62-f8cc4f616fd1) I do not know how to process file: #{filepath1}"
            }

        updatedObjectuuids.each{|objectuuid| Items::updateIndexAtObjectAttempt(objectuuid) }
    end

    # SystemEvents::writeEventToOutBuffer(event)
    def self.writeEventToOutBuffer(event)
        $system_events_out_buffer.synchronize {
            filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/system-events-out-buffer.jsonlines"
            File.open(filepath, "a"){|f| f.puts(JSON.generate(event)) }
        }
    end

    # SystemEvents::publishSystemEventsOutBuffer()
    def self.publishSystemEventsOutBuffer()
        $system_events_out_buffer.synchronize {
            filepath1 = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/system-events-out-buffer.jsonlines"
            return if !File.exists?(filepath1)
            return if IO.read(filepath1).strip.size == 0
            Machines::theOtherInstanceIds().each{|targetInstanceId|
                filepath2 = "#{Config::starlightCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.system-events.jsonlines"
                FileUtils.cp(filepath1, filepath2)
            }
            File.open(filepath1, "w"){|f| f.puts("") }
        }
    end
end
