

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::dequeueFirstValueOrNull(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Aether.rb"
=begin
    AetherGenesys::makeNewPoint(filepath)
    AetherKVStore::set(filepath, key, value)
    AetherKVStore::getOrNull(filepath, key)
    AetherKVStore::keys(filepath)
    AetherKVStore::destroy(filepath, key)
    AetherAionOperations::importLocationAgainstReference(filepath, xreference, location)
    AetherAionOperations::exportReferenceAtFolder(filepath, xreference, targetReconstructionFolderpath)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

=begin

InFlightControlSystem operates From 9am to 9pm.

At any point of time 
    - Each item has an index (starting from zero).

The time per day we expect from each is
    6 * (1 / 2^{index+1})

=end

class InFlightControlSystem

    # InFlightControlSystem::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------------------------------------
    # IO

    # InFlightControlSystem::pathToItems()
    def self.pathToItems()
        "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/InFlightControlSystem/Items"
    end

    # InFlightControlSystem::uuid2aetherfilepath(uuid)
    def self.uuid2aetherfilepath(uuid)
        aetherfilename = "#{uuid}.data"
        "#{InFlightControlSystem::pathToItems()}/#{aetherfilename}"
    end

    # InFlightControlSystem::newItemPayloadText(description, position, text)
    def self.newItemPayloadText(description, position, text)
        uuid = InFlightControlSystem::timeStringL22()
        aetherfilepath = InFlightControlSystem::uuid2aetherfilepath(uuid)
        AetherGenesys::makeNewPoint(aetherfilepath)
        AetherKVStore::set(aetherfilepath, "uuid", uuid)
        AetherKVStore::set(aetherfilepath, "description", description)
        AetherKVStore::set(aetherfilepath, "position", position)
        AetherKVStore::set(aetherfilepath, "payloadType", "text")
        AetherKVStore::set(aetherfilepath, "472ec67c0dd6", text)
    end

    # InFlightControlSystem::destroyItem(uuid)
    def self.destroyItem(uuid)
        filepath = InFlightControlSystem::uuid2aetherfilepath(uuid)
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -----------------------------------------------------------
    # Data

    # InFlightControlSystem::uuids()
    def self.uuids()
        Dir.entries(InFlightControlSystem::pathToItems())
            .select{|filename| filename[-5, 5] == ".data" }
            .map{|filename| filename[0, 22] }
            .sort
    end

    # InFlightControlSystem::getPosition(uuid)
    def self.getPosition(uuid)
        aetherfilepath = InFlightControlSystem::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "position").to_f
    end

    # InFlightControlSystem::getDescription(uuid)
    def self.getDescription(uuid)
        aetherfilepath = InFlightControlSystem::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "description")
    end

    # InFlightControlSystem::uuidsOrderedByPosition()
    def self.uuidsOrderedByPosition()
        InFlightControlSystem::uuids().sort{|uuid1, uuid2| InFlightControlSystem::getPosition(uuid1) <=> InFlightControlSystem::getPosition(uuid2) }
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # InFlightControlSystem::interactiveChoiceOfPosition()
    def self.interactiveChoiceOfPosition() # Float
        puts "Items"
        InFlightControlSystem::uuidsOrderedByPosition()
            .each{|uuid|
                puts "    - #{InFlightControlSystem::getPosition(uuid)} #{InFlightControlSystem::getDescription(uuid)}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # InFlightControlSystem::getAllUUIDsOrderedWithComputedOrdinal()
    def self.getAllUUIDsOrderedWithComputedOrdinal() # Array[ (uuid, ordinal: Int) ]
        InFlightControlSystem::uuidsOrderedByPosition()
            .map
            .with_index
            .to_a
    end

    # InFlightControlSystem::getCurrentOrdinalForUUIDOrNull(uuid)
    def self.getCurrentOrdinalForUUIDOrNull(uuid)
        InFlightControlSystem::getAllUUIDsOrderedWithComputedOrdinal()
            .select{|pair| pair[0] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # InFlightControlSystem::storedTimespan(uuid)
    def self.storedTimespan(uuid)
        BTreeSets::values(nil, "80a2e070-4501-4aa0-a24d-074a625b582f:#{uuid}")
            .inject(0, :+)
    end

    # InFlightControlSystem::uuidTotalTimespanIncludingLiveRun(uuid)
    def self.uuidTotalTimespanIncludingLiveRun(uuid)
        x0 = InFlightControlSystem::storedTimespan(uuid)
        x1 = 0
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{uuid}")
        if unixtime then
            x1 = Time.new.to_i - unixtime.to_i
        end
        x0 + x1
    end

    # InFlightControlSystem::timeToMetric(uuid, timeInSeconds, interfaceDiveIsRunning)
    def self.timeToMetric(uuid, timeInSeconds, interfaceDiveIsRunning)
        return 1 if InFlightControlSystem::isRunning(uuid)
        return 0 if interfaceDiveIsRunning # We kill other items when Interface Dive is running
        timeInHours = timeInSeconds.to_f/3600
        return + Math.atan(-timeInHours).to_f/1000 if timeInHours > 0
        0.76 + Math.atan(-timeInHours).to_f/1000
    end

    # InFlightControlSystem::insertTime(uuid, timeInSeconds)
    def self.insertTime(uuid, timeInSeconds)
        BTreeSets::set(nil, "80a2e070-4501-4aa0-a24d-074a625b582f:#{uuid}", SecureRandom.hex, timeInSeconds)
    end

    # InFlightControlSystem::metric(uuid)
    def self.metric(uuid)
        InFlightControlSystem::timeToMetric(uuid, InFlightControlSystem::storedTimespan(uuid), InFlightControlSystem::isRunning("20200502-141716-483780"))
    end

    # InFlightControlSystem::isWeekDay()
    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # InFlightControlSystem::operatingTimespanMapping()
    def self.operatingTimespanMapping()
        if InFlightControlSystem::isWeekDay() then
            {
                "GuardianGeneralWork" => 5 * 3600,
                "InterfaceDive"       => 3 * 3600,
                "IFCSStandard"        => 4 * 3600
            }
        else
            {
                "GuardianGeneralWork" => 0 * 3600,
                "InterfaceDive"       => 5 * 3600,
                "IFCSStandard"        => 5 * 3600
            }
        end
    end

    # InFlightControlSystem::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    def self.ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        InFlightControlSystem::operatingTimespanMapping()["IFCSStandard"] * (1.to_f / 2**(ordinal+1))
    end

    # InFlightControlSystem::itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
    def self.itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
        return nil if InFlightControlSystem::storedTimespan(uuid) < -3600 # This allows small targets to get some time and the big ones not to become overwelming
        if uuid == "20200502-141331-226084" then # Guardian General Work
            return InFlightControlSystem::operatingTimespanMapping()["GuardianGeneralWork"]
        end
        if uuid == "20200502-141716-483780" then 
            return InFlightControlSystem::operatingTimespanMapping()["InterfaceDive"]
        end
        InFlightControlSystem::ordinalTo24HoursTimeExpectationInSeconds(InFlightControlSystem::getCurrentOrdinalForUUIDOrNull(uuid))
    end

    # InFlightControlSystem::distributeDayTimeCommitmentsIfNotDoneAlready()
    def self.distributeDayTimeCommitmentsIfNotDoneAlready()
        return if Time.new.hour < 9
        InFlightControlSystem::uuidsOrderedByPosition()
            .each{|uuid|
                next if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
                timespan = InFlightControlSystem::itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
                next if timespan.nil?
                InFlightControlSystem::insertTime(uuid, -timespan)
                KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
            }
    end

    # InFlightControlSystem::isRunning(uuid)
    def self.isRunning(uuid)
        !KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{uuid}").nil?
    end

    # InFlightControlSystem::runTimeInSecondsOrNull(uuid)
    def self.runTimeInSecondsOrNull(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{uuid}")
        return nil if unixtime.nil?
        Time.new.to_i - unixtime.to_i
    end

    # -----------------------------------------------------------
    # Operations

    # InFlightControlSystem::start(uuid)
    def self.start(uuid)
        return if InFlightControlSystem::isRunning(uuid)
        KeyValueStore::set(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{uuid}", Time.new.to_i)
    end

    # InFlightControlSystem::stop(uuid)
    def self.stop(uuid)
        return if !InFlightControlSystem::isRunning(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{uuid}").to_i
        unixtime = unixtime.to_i
        KeyValueStore::destroy(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{uuid}")
        timespan = Time.new.to_i - unixtime
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        InFlightControlSystem::insertTime(uuid, timespan)
    end

    # InFlightControlSystem::itemToLongString(uuid)
    def self.itemToLongString(uuid)
        runTime = InFlightControlSystem::runTimeInSecondsOrNull(uuid)
        runTimeAsString = runTime ? " (running for #{(runTime.to_f/3600).round(2)} hours)" : "" 
        ordinal = InFlightControlSystem::getCurrentOrdinalForUUIDOrNull(uuid)
        expectation = InFlightControlSystem::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        expectationString = if ["20200502-141331-226084", "20200502-141716-483780"].include?(uuid) then
                                "special circumstances"
                            else
                                "expect: #{"%7.3f" % (expectation.to_f/3600)} hours"
                            end
        "position: #{"%6.3f" % InFlightControlSystem::getPosition(uuid)} | ordinal: #{ordinal} | #{expectationString} | time: #{"%6.3f" % (InFlightControlSystem::storedTimespan(uuid).to_f/3600)} | metric: #{"%6.3f" % InFlightControlSystem::metric(uuid)} | #{InFlightControlSystem::getDescription(uuid)} #{runTimeAsString}"
    end
end
