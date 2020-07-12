
# encoding: UTF-8

# require_relative "Tags.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require_relative "Quarks.rb"

require_relative "Cliques.rb"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class InMemoryWithOnDiskPersistenceValueCache
    @@XHash61CDAB202D6 = {}

    # InMemoryWithOnDiskPersistenceValueCache::set(key, value)
    def self.set(key, value)
        @@XHash61CDAB202D6[key] = value
        KeyValueStore::set(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}", JSON.generate([value]))
    end

    # InMemoryWithOnDiskPersistenceValueCache::getOrNull(key)
    def self.getOrNull(key)
        if @@XHash61CDAB202D6[key] then
            return @@XHash61CDAB202D6[key]
        end
        box = KeyValueStore::getOrNull(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}")
        if box then
            value = JSON.parse(box)[0]
            @@XHash61CDAB202D6[key] = value
            return value
        end
        nil
    end

    # InMemoryWithOnDiskPersistenceValueCache::delete(key)
    def self.delete(key)
        @@XHash61CDAB202D6.delete(key)
        KeyValueStore::destroy(nil, "07b3815a-9d77-49fa-ac07-c51524a0f381:#{key}")
    end
end
