
# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)
=end

require 'json'

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

# ---------------------------------------------------------------------------------------------

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# ---------------------------------------------------------------------------------------------

=begin

{
    "index" : Int,
    "length": Int
}

=end

class Mercury

    # ------------------------------------------------------
    # Private

    # Mercury::prefix(channel)
    def self.prefix(channel)
        "f79e2e1a-0fd5-40bd-9f34-2b08c0a1a06c:#{channel}"
    end

    # Mercury::getIndexObject(channel)
    def self.getIndexObject(channel)
        obj = KeyValueStore::getOrNull(nil, "#{Mercury::prefix(channel)}:9c0587c3-cdab-4404-a3c0-ba3cc744766c")
        if obj.nil? then
            obj = {
                "index"  => 0,
                "length" => 0
            }
        else
            obj = JSON.parse(obj)
        end
        obj
    end

    # Mercury::setIndexObject(channel, iobject)
    def self.setIndexObject(channel, iobject)
        if iobject["length"] == 0 then
            iobject["index"] == 0
        end
        KeyValueStore::set(nil, "#{Mercury::prefix(channel)}:9c0587c3-cdab-4404-a3c0-ba3cc744766c", JSON.generate(iobject))
    end

    # Mercury::setValue(channel, indx, value)
    def self.setValue(channel, indx, value)
        envelop = {
            "unixtime" => Time.new.to_i,
            "value"    => value
        }
        KeyValueStore::set(nil, "#{Mercury::prefix(channel)}:1485aa79-e621-4ab1-9ed1-4b8c60137d3d:#{indx}", JSON.generate(envelop))
    end

    # Mercury::getValueEnvelop(channel, indx)
    def self.getValueEnvelop(channel, indx)
        envelop = KeyValueStore::getOrNull(nil, "#{Mercury::prefix(channel)}:1485aa79-e621-4ab1-9ed1-4b8c60137d3d:#{indx}")
        # We are making the assumption that the index object is correct and that therefore
        # the envelop is not null
        raise "Mercury getValueEnvelop error (e4ad6a5e)" if envelop.nil?
        JSON.parse(envelop)
    end

    # Mercury::getFirstValueEnvelopOrNull(channel)
    def self.getFirstValueEnvelopOrNull(channel)
        iobject = Mercury::getIndexObject(channel)
        return nil if iobject["length"] == 0
        Mercury::getValueEnvelop(channel, iobject["index"])
    end

    # ------------------------------------------------------
    # Public Interface (1)

    # Mercury::postValue(channel, value)
    def self.postValue(channel, value)
        iobject = Mercury::getIndexObject(channel)
        Mercury::setValue(channel, iobject["index"]+iobject["length"], value)
        iobject["length"] = iobject["length"]+1
        Mercury::setIndexObject(channel, iobject)
    end

    # Mercury::getFirstValueOrNull(channel)
    def self.getFirstValueOrNull(channel)
        iobject = Mercury::getIndexObject(channel)
        return nil if iobject["length"] == 0
        envelop = Mercury::getValueEnvelop(channel, iobject["index"])
        envelop["value"]
    end

    # Mercury::deleteFirstValue(channel)
    def self.deleteFirstValue(channel)
        iobject = Mercury::getIndexObject(channel)
        return if iobject["length"] == 0
        iobject["index"] = iobject["index"]+1
        iobject["length"] = iobject["length"]-1
        Mercury::setIndexObject(channel, iobject)
    end

    # ------------------------------------------------------
    # Public Interface (1)

    # Mercury::getQueueSize(channel)
    def self.getQueueSize(channel)
        Mercury::getIndexObject(channel)["length"]
    end

    # Mercury::getAllValues(channel)
    def self.getAllValues(channel)
        iobject = Mercury::getIndexObject(channel)
        return [] if iobject["length"] == 0
        lowerBound = iobject["index"]
        upperBound = iobject["index"]+iobject["length"]-1
        (lowerBound..upperBound).map{|indx| Mercury::getValueEnvelop(channel, indx)["value"] }
    end

    # Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    def self.discardFirstElementsToEnforeQueueSize(channel, size)
        while Mercury::getQueueSize(channel) > size do
            Mercury::dequeueFirstValueOrNull(channel)
        end
    end

    # Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)
    def self.discardFirstElementsToEnforceTimeHorizon(channel, unixtime)
        loop {
            envelop = Mercury::getFirstValueEnvelopOrNull(channel)
            break if envelop.nil?
            break if unixtime <= envelop["unixtime"]
            Mercury::dequeueFirstValueOrNull(channel)
        }
    end

    # ------------------------------------------------------
    # Tests

    # Mercury::runTests()
    def self.runTests()
        channel = Time.new.to_s

        # Empty Queue
        raise "Error 100" if !(Mercury::getQueueSize(channel) == 0)
        raise "Error 200" if !(Mercury::getAllValues(channel) == [])
        raise "Error 300" if !(Mercury::getFirstValueOrNull(channel).nil?)
        raise "Error 500" if !(Mercury::dequeueFirstValueOrNull(channel).nil?)

        # Size 1
        Mercury::postValue(channel, "Alice")
        raise "Error 700" if !(Mercury::getQueueSize(channel) == 1)
        raise "Error 900" if !(Mercury::getAllValues(channel) == ["Alice"])
        raise "Error 910" if !(Mercury::getFirstValueOrNull(channel) == "Alice")
        raise "Error 930" if !(Mercury::dequeueFirstValueOrNull(channel) == "Alice")
        raise "Error 940" if !(Mercury::dequeueFirstValueOrNull(channel).nil?)
        raise "Error 942" if !(Mercury::getQueueSize(channel) == 0)

        # Size 2
        Mercury::postValue(channel, "Alice")
        Mercury::postValue(channel, "Bob")
        raise "Error 950" if !(Mercury::getQueueSize(channel) == 2)
        raise "Error 960" if !(Mercury::getAllValues(channel)[0] == "Alice")
        raise "Error 965" if !(Mercury::getAllValues(channel)[1] == "Bob")
        raise "Error 970" if !(Mercury::getFirstValueOrNull(channel) == "Alice")
        raise "Error 990" if !(Mercury::dequeueFirstValueOrNull(channel) == "Alice")
        raise "Error 992" if !(Mercury::dequeueFirstValueOrNull(channel)== "Bob")
        raise "Error 994" if !(Mercury::getQueueSize(channel) == 0)

        # Size 2
        Mercury::postValue(channel, "Alice")
        Mercury::postValue(channel, "Bob")
        raise "Error 111" if !(Mercury::getQueueSize(channel) == 2)
        raise "Error 112" if !(Mercury::getAllValues(channel)[0] == "Alice")
        raise "Error 113" if !(Mercury::getAllValues(channel)[1] == "Bob")
        raise "Error 114" if !(Mercury::getFirstValueOrNull(channel) == "Alice")
        raise "Error 116" if !(Mercury::dequeueFirstValueOrNull(channel) == "Alice")
        Mercury::postValue(channel, "Charles")
        raise "Error 117" if !(Mercury::dequeueFirstValueOrNull(channel) == "Bob")
        raise "Error 118" if !(Mercury::getQueueSize(channel) == 1)
        raise "Error 114" if !(Mercury::getFirstValueOrNull(channel) == "Charles")
        raise "Error 324" if !(Mercury::dequeueFirstValueOrNull(channel) == "Charles")
        raise "Error 334" if !(Mercury::getFirstValueOrNull(channel).nil?)

        puts "All tests completed"
    end
end
