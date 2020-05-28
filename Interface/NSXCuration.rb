# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/A10495.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

# ------------------------------------------------------------------------

class NSXCuration
    # NSXCuration::curation()
    def self.curation()
        # Nothing
    end
end


