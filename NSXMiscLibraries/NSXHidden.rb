
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# ----------------------------------------------------------------------

# We store the starting unixtime

HIDDEN_KVSTORE_REPOSITORY = "/Galaxy/DataBank/Catalyst/Hidden-KVStore-Repository"

class NSXHidden

    # NSXHidden::getPrefix()
    def self.getPrefix()
        prefix = KeyValueStore::getOrNull(HIDDEN_KVSTORE_REPOSITORY, "06406c69-12e1-4a5e-9128-21aeac22e64c:#{NSXMiscUtils::currentDay()}")
        return prefix if prefix
        prefix = SecureRandom.hex
        KeyValueStore::set(HIDDEN_KVSTORE_REPOSITORY, "06406c69-12e1-4a5e-9128-21aeac22e64c:#{NSXMiscUtils::currentDay()}", prefix)
        prefix
    end

    # NSXHidden::rotatePrefix()
    def self.rotatePrefix()
        prefix = SecureRandom.hex
        KeyValueStore::set(HIDDEN_KVSTORE_REPOSITORY, "06406c69-12e1-4a5e-9128-21aeac22e64c:#{NSXMiscUtils::currentDay()}", prefix)
    end

    # NSXHidden::setObjectHidden(objectuuid)
    def self.setObjectHidden(objectuuid)
        KeyValueStore::setFlagTrue(HIDDEN_KVSTORE_REPOSITORY, "#{NSXHidden::getPrefix()}:#{objectuuid}")
    end

    # NSXHidden::trueIfObjectHidden(objectuuid)
    def self.trueIfObjectHidden(objectuuid)
        KeyValueStore::flagIsTrue(HIDDEN_KVSTORE_REPOSITORY, "#{NSXHidden::getPrefix()}:#{objectuuid}")
    end

end


