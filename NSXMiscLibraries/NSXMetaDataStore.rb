
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

require "json"

NSXMetaDataStoreRepositoryFolderPath = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/NSXMetaDataStore/repository"

=begin
The starting idea was to have a metadata object for Catalyst Objects, 
but in the end I decided to make it more generic.
=end

class NSXMetaDataStore

    # NSXMetaDataStore::set(uid, key, value)
    def self.set(uid, key, value)
        KeyValueStore::set(NSXMetaDataStoreRepositoryFolderPath, key, JSON.generate([value]))
    end

    # NSXMetaDataStore::get(uid, key)
    def self.get(uid, key)
        value = KeyValueStore::getOrNull(NSXMetaDataStoreRepositoryFolderPath, key)
        return nil if value.nil?
        JSON.parse(value).first
    end
end
