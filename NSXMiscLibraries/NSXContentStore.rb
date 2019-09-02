#!/usr/bin/ruby

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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

class NSXContentStore

    # NSXContentStore::getItemOrNull(contentStoreItemId: String): ContentsStoreItem or null
    def self.getItemOrNull(contentStoreItemId)
        # First we look up the hash of the file
        sha1hash = KeyValueStore::getOrNull("#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Content-Store/Mapping-Id-Content", contentStoreItemId)
        return nil if sha1hash.nil?
        # Second we look for the file
        pathfragment = "#{sha1hash[0,2]}/#{sha1hash[2,2]}/#{sha1hash}.json"
        filepath = "#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Content-Store/Content/#{pathfragment}"
        if !File.exists?(filepath) then
            raise "Error 8ce029e4: Found a hash againt a contentStoreItemId, but no content"
        end
        JSON.parse(IO.read(filepath))
    end

    # NSXContentStore::setItem(contentStoreItemId, contentStoreItem)
    def self.setItem(contentStoreItemId, contentStoreItem)
        contentStoreItemAsString = JSON.generate(contentStoreItem)
        sha1hash = Digest::SHA1.hexdigest(contentStoreItemAsString)
        KeyValueStore::set("#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Content-Store/Mapping-Id-Content", contentStoreItemId, sha1hash)
        pathfragment = "#{sha1hash[0,2]}/#{sha1hash[2,2]}/#{sha1hash}.json"
        filepath = "#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Content-Store/Content/#{pathfragment}"
        # return if File.exists?(filepath) # Content Adressable Storage
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(contentStoreItemAsString) }
    end

end