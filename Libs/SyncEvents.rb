
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

        raise "(error: )"
    end
end

class SyncEventSpecific
    # SyncEventSpecific::sendObjectUpdateEvent(object, machineName)
    def self.sendObjectUpdateEvent(object, machineName)
        event = {
            "type"    => "new-object",
            "payload" => object
        }
        SyncEventsBase::putEventForMachine(event, machineName)
    end
end