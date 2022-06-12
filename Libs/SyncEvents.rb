
# encoding: UTF-8

class SyncEventsBase

    # SyncEventsBase::putEventForMachine(event, machineName)
    def self.putEventForMachine(event, machineName)
        Mercury::postValue("75D88016-56AA-4729-992A-F1FF62AAF893:#{machineName}", event)
    end

    # SyncEventsBase::processEvent(event)
    def self.processEvent(event)
        puts "processing event:"
        puts JSON.pretty_generate(event)
    end
end

class SyncEventSpecific
    # SyncEventSpecific::sendObjectUpdateEvent(object, machineName)
    def self.sendObjectUpdateEvent(object)
        event = {
            "type"    : "new-object",
            "payload" : object
        }
        SyncEventsBase::putEventForMachine(event, machineName)
    end
end