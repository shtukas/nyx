
# encoding: UTF-8

$BufferTimes = []

class SystemEventsBuffering

    # SystemEventsBuffering::shouldPublishBufferNow()
    def self.shouldPublishBufferNow()
        $system_events_out_buffer.synchronize {
            $BufferTimes = $BufferTimes.select{|time| (Time.new.to_f - time) < 20 }
        }
        # We publish if there's been less than 20 hits over the last 20 seconds
        ($BufferTimes.size < 20)
    end

    # SystemEventsBuffering::eventToOutBuffer(event)
    def self.eventToOutBuffer(event)
        $system_events_out_buffer.synchronize {
            filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/system-events-out-buffer.jsonlines"
            File.open(filepath, "a"){|f| f.puts(JSON.generate(event)) }
            $BufferTimes << Time.new.to_f
        }
        if SystemEventsBuffering::shouldPublishBufferNow() then
            SystemEventsBuffering::outBufferToCommsLine()
        end
    end

    # SystemEventsBuffering::outBufferToCommsLine()
    def self.outBufferToCommsLine()
        $system_events_out_buffer.synchronize {
            filepath1 = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/system-events-out-buffer.jsonlines"
            return if !File.exists?(filepath1)
            return if IO.read(filepath1).strip.size == 0
            Machines::theOtherInstanceIds().each{|targetInstanceId|
                filepath2 = "#{StargateMultiInstanceShared::pathToCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.system-events.jsonlines"
                FileUtils.cp(filepath1, filepath2)
            }
            File.open(filepath1, "w"){|f| f.puts("") }
        }
    end
end

class SystemEvents

    # SystemEvents::process(event)
    def self.process(event)

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
            SystemEvents::process({
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
        #puts "SystemEvents::broadcast(#{JSON.pretty_generate(event)})"
        SystemEventsBuffering::eventToOutBuffer(event)
    end

    # SystemEvents::sendTo(event, targetInstanceId)
    def self.sendTo(event, targetInstanceId)
        filepath = "#{StargateMultiInstanceShared::pathToCommsLine()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.event.json"
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

        folderpath = "#{StargateMultiInstanceShared::pathToCommsLine()}/#{instanceId}"

        LucilleCore::locationsAtFolder(folderpath)
            .each{|filepath1|

                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")
                next if File.basename(filepath1).include?("sync-conflict")

                if File.basename(filepath1)[-11, 11] == ".event.json" then
                    e = JSON.parse(IO.read(filepath1))
                    if verbose then
                        puts "SystemEvents::processCommsLine: event: #{JSON.pretty_generate(e)}"
                    end
                    SystemEvents::process(e)
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
                    Items::syncWithEventLog()
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
end
