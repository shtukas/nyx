
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
            FileSystemCheck::fsckAttributeUpdateV2(event, SecureRandom.hex)
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
    end

    # SystemEvents::broadcast(event)
    def self.broadcast(event)
        SystemEventsBuffering::putToBroadcastOutBuffer(event)
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
                filepath = "#{CommsLine::pathToStaging()}/#{targetInstanceId}/#{l22}.system-events.jsonlines"
                File.open(filepath, "a"){|f| f.puts(JSON.generate(event)) }
            }
            Mercury2::dequeue(channel)
        }
    end
end