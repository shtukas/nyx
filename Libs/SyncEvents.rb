
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

        if event["type"] == "new-object" then
            remoteItem = event["payload"]

            localItem = Librarian::getObjectByUUIDOrNull(remoteItem["uuid"])

            if localItem.nil? then
                #puts "Adding new item from Lucille20"
                #puts JSON.pretty_generate(remoteItem)
                Librarian::commitWithoutUpdates(remoteItem)
                return
            end

            if  Genealogy::areEquivalent(localItem, remoteItem) then
                return
            end

            if Genealogy::firstIsStrictAncestorOfSecond(remoteItem, localItem) then
                # The local version localItem, is newer
                return
            end

            if Genealogy::firstIsStrictAncestorOfSecond(localItem, remoteItem) then
                puts JSON.pretty_generate(remoteItem)
                Librarian::commitWithoutUpdates(remoteItem)
                return
            end

            # By now we have a conflict
            puts JSON.pretty_generate(localItem).green
            puts JSON.pretty_generate(remoteItem).red
            exit
        end

        if event["type"] == "do-not-show-until" then
            uuid = event["uuid"]
            targetUnixtime = event["targetUnixtime"]
            DoNotShowUntil::setUnixtime(uuid, targetUnixtime)
            return
        end

        raise "(error: b48c1418-607d-4bd7-99d0-12e1af14ce25) event: #{event}"
    end
end

class SyncEventSpecific

    # SyncEventSpecific::postObjectUpdateEvent(object, machineName)
    def self.postObjectUpdateEvent(object, machineName)
        event = {
            "type"    => "new-object",
            "payload" => object
        }
        SyncEventsBase::putEventForMachine(event, machineName)
    end

    # SyncEventSpecific::postDoNotShowUntil(uuid, targetUnixtime, machineName)
    def self.postDoNotShowUntil(uuid, targetUnixtime, machineName)
        event = {
            "type" => "do-not-show-until",
            "uuid" => uuid,
            "targetUnixtime" => targetUnixtime
        }
        SyncEventsBase::putEventForMachine(event, machineName)
    end
end