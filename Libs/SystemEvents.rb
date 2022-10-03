
# encoding: UTF-8

class SystemEvents

    # SystemEvents::internal(event)
    def self.internal(event)

        #puts "SystemEvent(#{JSON.pretty_generate(event)})"

        # ordering: as they come

        if event["mikuType"] == "TxBankEvent" then
            Bank::processEvent(event)
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEvent(event)
        end

        if event["mikuType"] == "bank-account-done-today" then
            BankAccountDoneForToday::processEvent(event)
        end

        if event["mikuType"] == "NxDeleted" then
            objectuuid = event["objectuuid"]
            NxDeleted::deleteObjectNoEvents(objectuuid)
            SystemEvents::internal({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => objectuuid
            })
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

        if event["mikuType"] == "bank-account-set-un-done-today" then
            BankAccountDoneForToday::processEvent(event)
        end

        $CatalystAlfred1.processEvent(event)
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        SystemEventsBuffering::putToBroadcastOutBuffer(event)
    end

    # SystemEvents::internalCommsLine(verbose)
    def self.processCommsLine(verbose)
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder

        updatedObjectuuids = []

        instanceId = Config::get("instanceId")

        folderpath = "#{StargateMultiInstanceShared::pathToCommsLine()}/#{instanceId}"

        LucilleCore::locationsAtFolder(folderpath)
            .each{|filepath1|

                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")
                next if File.basename(filepath1).include?("sync-conflict")

                if File.basename(filepath1)[-11, 11] == ".event.json" then
                    e = JSON.parse(IO.read(filepath1))
                    if verbose then
                        puts "SystemEvents::internalCommsLine: event: #{JSON.pretty_generate(e)}"
                    end
                    SystemEvents::internal(e)
                    FileUtils.rm(filepath1)
                    next
                end

                if CommonUtils::ends_with?(File.basename(filepath1), "items-events-log.sqlite3") then
                    if verbose then
                        puts "SystemEvents::internalCommsLine: reading: items-events-log.sqlite3"
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
                    Items::syncWithEventLog()
                    next
                end

                if CommonUtils::ends_with?(filepath1, ".system-events.jsonlines") then

                    if verbose then
                        puts "SystemEvents::internalCommsLine: reading: #{File.basename(filepath1)}"
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
                            SystemEvents::internal(event)
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
end

class SystemEventsBuffering

    # SystemEventsBuffering::putToBroadcastOutBuffer(event)
    def self.putToBroadcastOutBuffer(event)
        Mercury2::put("a0b54bbe-96f8-4f19-911e-88c3f47eabdd", event)
    end

    # SystemEventsBuffering::broadcastOutBufferToCommsline()
    def self.broadcastOutBufferToCommsline()
        channel = "a0b54bbe-96f8-4f19-911e-88c3f47eabdd"
        l22 = CommonUtils::timeStringL22()
        loop {
            event = Mercury2::readFirstOrNull(channel)
            break if event.nil?
            puts "broadcast: #{JSON.pretty_generate(event)}"
            Machines::theOtherInstanceIds().each{|targetInstanceId|
                filepath = "#{StargateMultiInstanceShared::pathToCommsLine()}/#{targetInstanceId}/#{l22}.system-events.jsonlines"
                File.open(filepath, "a"){|f| f.puts(JSON.generate(event)) }
            }
            Mercury2::dequeue(channel)
        }
    end
end