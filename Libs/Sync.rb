
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

            if remoteItem["mikuType"] == "NxDeleted" then
                # We do not store a "NxDeleted" is there was no object already
                return if Librarian::getObjectByUUIDOrNull(remoteItem["uuid"]).nil?
                Librarian::commitWithoutUpdatesNoEvents(remoteItem)
                return
            end

            localItem = Librarian::getObjectByUUIDOrNull(remoteItem["uuid"])

            if localItem.nil? then
                #puts "Adding new item from Lucille20"
                #puts JSON.pretty_generate(remoteItem)
                Librarian::commitWithoutUpdatesNoEvents(remoteItem)
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
                Librarian::commitWithoutUpdatesNoEvents(remoteItem)
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
            DoNotShowUntil::setUnixtimeNoEvents(uuid, targetUnixtime)
            return
        end

        raise "(error: b48c1418-607d-4bd7-99d0-12e1af14ce25) event: #{event}"
    end
end

class SyncEventSpecific

    # SyncEventSpecific::postObjectUpdateEvent(object)
    def self.postObjectUpdateEvent(object)
        event = {
            "type"    => "new-object",
            "payload" => object
        }
        SyncEventsBase::putEventForMachine(event, Machines::theOtherMachine())
    end

    # SyncEventSpecific::postDoNotShowUntil(uuid, targetUnixtime, machineName)
    def self.postDoNotShowUntil(uuid, targetUnixtime, machineName)
        event = {
            "type" => "do-not-show-until",
            "uuid" => uuid,
            "targetUnixtime" => targetUnixtime
        }
        SyncEventsBase::putEventForMachine(event, Machines::theOtherMachine())
    end
end

class SyncServerService

  def getEventForClientOrNull()
    event = Mercury::dequeueFirstValueOrNull("75D88016-56AA-4729-992A-F1FF62AAF893:#{Machines::theOtherMachine()}")
    return if event.nil?
    if verbose then
        puts "outgoing event:"
        puts JSON.pretty_generate(event)
    end
    event
  end

  def getBlobOrNull(nhash)
    EnergyGridDatablobs::getBlobOrNull(nhash)
  end
end

class SyncOperators

    # SyncOperators::clientRunOnce(verbose)
    def self.clientRunOnce(verbose)
        otherMachineIP = Machines::theOtherMachineIP()
        loop {
            begin
                event = DRbObject.new(nil, "druby://#{otherMachineIP}:9876").getEventForClientOrNull()
                break if event.nil?
                puts "incoming event:"
                puts JSON.pretty_generate(event)
                SyncEventsBase::processEvent(event)
            rescue => error
                if verbose then
                    puts error.message
                end
                break
            end
        }
    end

    # SyncOperators::serverRun(verbose)
    def self.serverRun(verbose)
        ip = Machines::thisMachineIP()
        puts "Starting server @ ip: #{ip}"
        DRb.start_service("druby://#{ip}:9876", SyncServerService.new())
        DRb.thread.join
    end
end
