
# encoding: UTF-8

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

# -----------------------------------------------------------------

class TheCacheWithLambdas

    # TheCacheWithLambdas::invalidate(uuid)
    def self.invalidate(uuid)
        KeyValueStore::destroy(nil, uuid)
    end

    # TheCacheWithLambdas::get(uuid, compute, cacheExpiryInSeconds)
    def self.get(uuid, compute, cacheExpiryInSeconds)

        computeAndStore = lambda { |uuid, compute|
            value = compute.call()
            packet = {
                "unixtime" => Time.new.to_i,
                "value" => value
            }
            KeyValueStore::set(nil, uuid, JSON.generate(packet))
            value
        }

        packet = KeyValueStore::getOrNull(nil, uuid)

        if packet.nil? then
            return computeAndStore.call(uuid, compute)
        else
            packet = JSON.parse(packet)
            if (Time.new.to_i - packet["unixtime"]) < cacheExpiryInSeconds then
                return packet["value"]
            else
                return computeAndStore.call(uuid, compute)
            end
        end
    end
end
