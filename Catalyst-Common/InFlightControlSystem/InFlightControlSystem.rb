
# require_relative "../Catalyst-Common/InFlightControlSystem/InFlightControlSystem.rb"

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
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
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

require_relative "../Catalyst-Common.rb"

# -----------------------------------------------------------------

=begin

{
    "targetuid"   : String
    "description" : String
    "position"    : Float

    "filepath"    : String 
        # Automatically computed at retrieval time, helps with the deletion of the item
        # Not set for managed items: dive and ggw items
}

Special Purpose Items:

{
  "targetuid": "8D80531C-E98F-4553-A815-6D3284DE0FF8",
  "description": "🛩️",
  "position": 0
}

{
  "targetuid": "6705C595-3B8A-437C-B351-9D9304B162AD",
  "description": "Guardian General Work",
  "position": 1
}


Time provisioning:

    InFlightControlSystem operates From 9am to 9pm.

    At any point of time 
        1. We collect the active items (not hidden by DoNotShow)
        2. Each has an index (starting from zero).

    The time per day we expect from each is
        6 * (1 / 2^{index})

    The items which are late are shown, those which are not are not shown

=end

class InFlightControlSystem
    # InFlightControlSystem::start(targetuid)
    def self.start(targetuid)
        return if InFlightControlSystem::isRunning(targetuid)
        KeyValueStore::set(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuid}", Time.new.to_i)
    end

    # InFlightControlSystem::stop(targetuid)
    def self.stop(targetuid) # Float or Null # latter if it wasn't running.
        return if !InFlightControlSystem::isRunning(targetuid)
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuid}").to_i
        unixtime = unixtime.to_i
        KeyValueStore::destroy(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuid}")
        timespan = Time.new.to_i - unixtime
        timespan = [timespan, 3600*2].min 
            # To avoid problems after leaving things running 
            # or when we create a new top three item while something was running.
        Mercury::postValue("7ee6b697-ced5-4b43-8724-405d9e744971:#{targetuid}", timespan)
    end

    # InFlightControlSystem::destroyItem(targetuid)
    def self.destroyItem(targetuid)
        IFCS::itemsOrderedByPosition()
            .select{|item| item["targetuid"] == targetuid }
            .each{|item|
                FileUtils.rm(item["filepath"])
            }
    end

    # InFlightControlSystem::newItemInteractive(targetuid, description)
    def self.newItemInteractive(targetuid, description)
        position = IFCS::interactiveChoiceOfPosition()
        IFCS::newItem(targetuid, description, position)
    end

    # InFlightControlSystem::isRunning(targetuid)
    def self.isRunning(targetuid)
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuid}")
        !unixtime.nil?
    end

    # InFlightControlSystem::isRegistered(targetuid)
    def self.isRegistered(targetuid) # Boolean
        IFCS::itemsOrderedByPosition()
            .any?{|item| item["targetuid"] == targetuid }
    end

    # InFlightControlSystem::runTimeInSecondsOrNull(targetuid)
    def self.runTimeInSecondsOrNull(targetuid)
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuid}")
        return nil if unixtime.nil?
        Time.new.to_i - unixtime.to_i
    end

    # InFlightControlSystem::catalistItemIFCSTransmutation(targetuid, object)
    def self.catalistItemIFCSTransmutation(targetuid, object)
        # This function helps clients of IFCS to implement the logic around overriding the metric 
        # if that items was registered in IFCS.
        return object if !InFlightControlSystem::isRegistered(targetuid)
        # The object is registered. We first need to override the metric


        timeDifferentialAsString = (IFCS::targetTimeDifferentialInSecondsOrNull(targetuid).to_f/3600).round(2)
        runTime = InFlightControlSystem::runTimeInSecondsOrNull(targetuid)
        runTimeAsString = runTime ? " (running for #{(runTime.to_f/3600).round(2)} hours)" : "" 

        if object["contentItem"]["type"] == "line" then
            object["contentItem"]["line"] = "[ifcs #{timeDifferentialAsString}#{runTimeAsString}] #{object["contentItem"]["line"]}"
        end
        if object["contentItem"]["type"] == "line-and-body" then
            object["contentItem"]["line"] = "[ifcs #{timeDifferentialAsString}#{runTimeAsString}] #{object["contentItem"]["line"]}"
            object["contentItem"]["body"] = "[ifcs #{timeDifferentialAsString}#{runTimeAsString}]\n#{object["contentItem"]["body"]}"
        end
        object["metric"] = (IFCS::targetToMetricOrNull(targetuid) || 2.718)
        object["isRunning"] = InFlightControlSystem::isRunning(targetuid)
        object
    end
end

class IFCS

    # IFCS::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # IFCS::isOperating()
    def self.isOperating()
        Time.new.hour >= 9 and Time.new.hour < 21
    end

    # IFCS::operatingTimespanInHours()
    def self.operatingTimespanInHours()
        12
    end

    # -----------------------------------------------------------
    # Making

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # IFCS::interactiveChoiceOfPosition()
    def self.interactiveChoiceOfPosition() # Float
        puts "Items"
        IFCS::itemsOrderedByPosition()
            .each{|item|
                puts "    - #{item["position"]} #{item["description"]}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # Creates a new entry in the tracking repository
    # IFCS::newItem(targetuid, description, position)
    def self.newItem(targetuid, description, position)
        item = {
            "targetuid"       => targetuid,
            "description"     => description,
            "position"        => position
        }
        filename = "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/#{IFCS::timeStringL22()}.json"
        File.open(filename, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # -----------------------------------------------------------
    # Querying Items

    # IFCS::getDiveItem()
    def self.getDiveItem()
        {
          "targetuid"   => "8D80531C-E98F-4553-A815-6D3284DE0FF8",
          "description" => "🛩️",
          "position"    => 2
        }
    end

    # IFCS::getGGWItem()
    def self.getGGWItem()
        item = {
          "targetuid"   => "6705C595-3B8A-437C-B351-9D9304B162AD",
          "description" => "Guardian General Work",
          "position"    => 1
        }
        shouldIssueItem = [1, 2, 3, 4, 5].include?(Time.new.wday)
        shouldIssueItem ? item : nil
    end

    # IFCS::itemsOrderedByPosition()
    def self.itemsOrderedByPosition()
        items1 = [ IFCS::getDiveItem(), IFCS::getGGWItem() ].compact
        items2 = Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem")
                    .select{|filename| filename[-5, 5] == ".json" }
                    .map{|filename| "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/#{filename}" }
                    .map{|filepath| 
                        item = JSON.parse(IO.read(filepath))
                        item["filepath"] = filepath
                        item
                    }
        (items1 + items2).sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # IFCS::getAllActiveItemsOrderedWithComputedOrdinal()
    def self.getAllActiveItemsOrderedWithComputedOrdinal() # Array[ (item: Item, ordinal: Int) ]
        # Todo: Take account of DoNotShowUntil...
        IFCS::itemsOrderedByPosition()
            .map
            .with_index
            .to_a
    end

    # -----------------------------------------------------------
    # Data Operations

    # IFCS::getCurrentOrdinalForTargetOrNull(targetuid)
    def self.getCurrentOrdinalForTargetOrNull(targetuid)
        IFCS::getAllActiveItemsOrderedWithComputedOrdinal()
            .select{|pair| pair[0]['targetuid'] == targetuid }
            .map{|pair| pair[1] }
            .first
    end

    # IFCS::targetTimePointsLast24Hours(targetuid)
    def self.targetTimePointsLast24Hours(targetuid)
        channel = "7ee6b697-ced5-4b43-8724-405d9e744971:#{targetuid}"
        Mercury::discardFirstElementsToEnforceTimeHorizon(channel, Time.new.to_i - 86400)
        Mercury::getAllValues(channel)
    end

    # IFCS::targetStoredTotalTimespanLast24Hours(targetuid)
    def self.targetStoredTotalTimespanLast24Hours(targetuid)
        IFCS::targetTimePointsLast24Hours(targetuid).inject(0, :+)
    end

    # IFCS::targetLiveTotalTimespanLast24Hours(targetuid)
    def self.targetLiveTotalTimespanLast24Hours(targetuid)
        x0 = IFCS::targetStoredTotalTimespanLast24Hours(targetuid)
        x1 = 0
        unixtime = KeyValueStore::getOrNull(nil, "b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuid}")
        if unixtime then
            x1 = Time.new.to_i - unixtime.to_i
        end
        x0 + x1
    end

    # IFCS::targetuidWithOrdinalTo24HoursTimeExpectationInSeconds(targetuid, ordinal)
    def self.targetuidWithOrdinalTo24HoursTimeExpectationInSeconds(targetuid, ordinal)
        3600 * IFCS::operatingTimespanInHours() * (1.to_f / 2**(ordinal+1))
    end

    # IFCS::targetWithOrdinalTimeDifferentialInSeconds(targetuid, ordinal)
    def self.targetWithOrdinalTimeDifferentialInSeconds(targetuid, ordinal)
        IFCS::targetLiveTotalTimespanLast24Hours(targetuid) - IFCS::targetuidWithOrdinalTo24HoursTimeExpectationInSeconds(targetuid, ordinal)
    end

    # IFCS::targetTimeDifferentialInSecondsOrNull(targetuid)
    def self.targetTimeDifferentialInSecondsOrNull(targetuid)
        ordinal = IFCS::getCurrentOrdinalForTargetOrNull(targetuid)
        return nil if ordinal.nil?
        IFCS::targetWithOrdinalTimeDifferentialInSeconds(targetuid, ordinal)
    end

    # IFCS::timeDifferentialToMetric(targetuid, timedifferential)
    def self.timeDifferentialToMetric(targetuid, timedifferential)
        return 1 if InFlightControlSystem::isRunning(targetuid)
        timeInHours = timedifferential.to_f/3600
        return (0.75 + Math.atan(-timeInHours).to_f/1000) if timeInHours < -1
        0.75*Math.exp(-timeInHours-1)

        # -3600*2 -> 0.75
        # -3600   -> 0.75
        # -300    -> 0.29988724075863554
        #  0      -> 0.27590958087858175
    end

    # IFCS::targetToMetricOrNull(targetuid)
    def self.targetToMetricOrNull(targetuid)
        timedifferential = IFCS::targetTimeDifferentialInSecondsOrNull(targetuid)
        return nil if timedifferential.nil?
        IFCS::timeDifferentialToMetric(targetuid, timedifferential)
    end

    # -----------------------------------------------------------
    # User Interface

    # IFCS::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end
end
