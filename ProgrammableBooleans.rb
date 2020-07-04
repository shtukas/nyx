
# encoding: UTF-8

# require_relative "ProgrammableBooleans.rb"
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

    # ProgrammableBooleans::resetTrueNoMoreOften(uuid)
    def self.resetTrueNoMoreOften(uuid)
        KeyValueStore::set(nil, uuid, Time.new.to_f)
    end

    # ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds(uuid, n)
    def self.trueNoMoreOftenThanEveryNSeconds(uuid, n)
        lastTimestamp = KeyValueStore::getOrDefaultValue(nil, uuid, "0").to_f
        return false if (Time.new.to_f - lastTimestamp) < n
        ProgrammableBooleans::resetTrueNoMoreOften(uuid)
        true
    end
end
