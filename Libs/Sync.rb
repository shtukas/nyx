
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
                Librarian::destroyByNxDeletedEmitNoEvent(remoteItem["uuid"])
                return
            end

            puts "FileSystemCheck:"
            operator = CompositeElizabeth.new(EnergyGridElizabeth.new(), [TheOtherMachineElizabeth.new()])
            FileSystemCheck::fsckLibrarianMikuObjectExitAtFirstFailure(remoteItem, operator)

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

=begin
    Mercury::postValue(channel, value)
    Mercury::readFirstValueOrNull(channel)
    Mercury::dequeueFirstValueOrNull(channel)
    Mercury::isEmpty(channel)
=end

class SyncServerService

  def initialize(verbose)
    @verbose = verbose
  end

  def getEventForClientOrNull()
    event = Mercury::readFirstValueOrNull("75D88016-56AA-4729-992A-F1FF62AAF893:#{Machines::theOtherMachine()}")
    return if event.nil?
    if @verbose then
        puts "outgoing event:"
        puts JSON.pretty_generate(event)
    end
    event
  end

  def dequeue()
    Mercury::dequeueFirstValueOrNull("75D88016-56AA-4729-992A-F1FF62AAF893:#{Machines::theOtherMachine()}")
  end

  def getBlobOrNull(nhash)
    EnergyGridDatablobs::getBlobOrNull(nhash)
  end
end

class TheOtherMachineElizabeth

    def commitBlob(blob)
        raise "(error: DB18899C-2D5C-4A88-B01B-01A8D28F574E)"
    end

    def filepathToContentHash(filepath)
        raise "(error: 15167BF3-5496-46BA-B128-D63363FAEE15)"
    end

    def getBlobOrNull(nhash)
        begin
            ip = Machines::theOtherMachineIP()
            puts "(TheOtherMachineElizabeth downloading blob from #{Machines::theOtherMachine()}) #{nhash}"
            blob = DRbObject.new(nil, "druby://#{ip}:9876").getBlobOrNull(nhash)
            return blob if blob
        rescue
        end
        nil
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "TheOtherMachineElizabeth (error: 2A5982F1-6809-42E8-A0CA-B238C5ADAD1A) could not find blob, nhash: #{nhash}"
        raise "(error: 57FE180A-1514-4B61-BDC9-4731666F5DD6, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: F4C1F4E3-7DF6-480B-8E41-2E721316ED41) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
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

                # At the beginning we were doing `Mercury::dequeueFirstValueOrNull` in the service. We have moved to
                # Mercury::readFirstValueOrNull in the Service to avoid losing messages that happen to fail 
                # during procesing. That change implies that a dequeue must then happen.
                # 
                # The next instruction dequeues, but technically this is not a good way to do it because of 
                # potential race conditions. They will not happen with our current setting of 
                # only one client and one server though.
                # 
                # This is just to mention that we are aware of the potential for a race condition if the 
                # system expands.
                DRbObject.new(nil, "druby://#{otherMachineIP}:9876").dequeue()
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
        DRb.start_service("druby://#{ip}:9876", SyncServerService.new(verbose))
        DRb.thread.join
    end
end