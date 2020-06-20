
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/ProgrammableBooleans.rb"
=begin
    ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds(uuid, n)
=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

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

# -----------------------------------------------------------------

class ProgrammableBooleans

    # ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds(uuid, n)
    def self.trueNoMoreOftenThanEveryNSeconds(uuid, n)
        key = CatalystCommon::getNewValueEveryNSeconds(uuid, n)
        if !KeyValueStore::flagIsTrue(nil, key) then
            KeyValueStore::setFlagTrue(nil, key)
            return true
        end
        false
    end
end
