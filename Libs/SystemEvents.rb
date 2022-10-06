
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
        end

        if event["mikuType"] == "AttributeUpdate" then
            objectuuid = event["objectuuid"]
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"]
            attname    = event["attname"]
            attvalue   = event["attvalue"]
            Items::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
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
            FileSystemCheck::fsckAttributeUpdateV2(event, SecureRandom.hex, false)
            objectuuid = event["objectuuid"]
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"]
            attname    = event["attname"]
            attvalue   = event["attvalue"]
            Items::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
        end

        if event["mikuType"] == "bank-account-set-un-done-today" then
            BankAccountDoneForToday::processEvent(event)
        end

        if event["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::pushItemUpdate(event)
        end

        if event["mikuType"] == "datastore4-kv-object-set" then
            key    = event["key"]
            object = event["object"]
            DataStore4KVObjects::setObject(key, object)
        end
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        Machines::theOtherInstanceIds().each{|targetInstanceId|
            filepath = "#{CommsLine::pathToStaging()}/#{targetInstanceId}/#{CommonUtils::timeStringL22()}.system-event.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        }
    end

    # SystemEvents::processIncomingEventsFromLine(verbose)
    def self.processIncomingEventsFromLine(verbose)
        # New style. Keep while we process the remaining items
        # We are reading from the instance folder

        instanceId = Config::get("instanceId")

        folderpath = "#{CommsLine::pathToActive()}/#{instanceId}"

        LucilleCore::locationsAtFolder(folderpath)
            .each{|filepath1|

                next if !File.exists?(filepath1)
                next if File.basename(filepath1).start_with?(".")
                next if File.basename(filepath1).include?("sync-conflict")

                if verbose then
                    puts "SystemEvents::processIncomingEventsFromLine: processing: #{File.basename(filepath1)}"
                end

                if CommonUtils::ends_with?(filepath1, ".system-event.json") then
                    event = JSON.parse(IO.read(filepath1))
                    puts "system event from commsline: #{JSON.pretty_generate(event)}"
                    SystemEvents::internal(event)
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
    end
end