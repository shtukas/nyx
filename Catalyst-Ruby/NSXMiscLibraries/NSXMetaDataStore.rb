
# encoding: UTF-8

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
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

Keys:

    runtimes-targets-1738: null or Array[String] 
        If the object is runnable (determined by the kind of NSX content store item it carries)
        Then the time it has created while running is reported to those other uids

    runtimes-targets-1832: null or Array[String]

=end

class NSXMetaDataStore

    # NSXMetaDataStore::get(uid)
    def self.get(uid)
        value = KeyValueStore::getOrNull(NSXMetaDataStoreRepositoryFolderPath, uid)
        return {} if value.nil?
        JSON.parse(value)
    end

    # NSXMetaDataStore::set(uid, key, value)
    def self.set(uid, key, value)
        metadata = NSXMetaDataStore::get(uid)
        metadata[key] = value
        KeyValueStore::set(NSXMetaDataStoreRepositoryFolderPath, uid, JSON.generate(metadata))
        NSXMultiInstancesWrite::sendEventToDisk({
            "instanceName" => NSXMiscUtils::instanceName(),
            "eventType"    => "MultiInstanceEventType:MetaDataStoreUpdate",
            "payload"      => {
                "uid"   => uid,
                "key"   => key,
                "value" => value
            }
        })
    end

    # NSXMetaDataStore::setFromMultiInstanceProcessing(uid, key, value)
    def self.setFromMultiInstanceProcessing(uid, key, value)
        metadata = NSXMetaDataStore::get(uid)
        metadata[key] = value
        KeyValueStore::set(NSXMetaDataStoreRepositoryFolderPath, uid, JSON.generate(metadata))
    end

    # NSXMetaDataStore::uiEditCatalystObjectMetadata(object)
    def self.uiEditCatalystObjectMetadata(object)
        puts "Catalyst Object Metadata Edit"
        puts NSXDisplayUtils::objectDisplayStringForCatalystListing(object, false, 1)
        options = ["add streamuuid target for run times"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option == "add streamuuid target for run times" then
            stream = NSXStreamsUtils::interactivelySelectStreamOrNull()
            return if stream.nil?
            streamuuid = stream["streamuuid"]
            metadata = NSXMetaDataStore::get(object["uuid"])
            targets = ((metadata["runtimes-targets-1738"] || []) + [streamuuid]).uniq
            NSXMetaDataStore::set(object["uuid"], "runtimes-targets-1738", targets)
        end
        LucilleCore::pressEnterToContinue()
    end

    # NSXMetaDataStore::enrichMetadataObject(objectuuid, metadata)
    def self.enrichMetadataObject(objectuuid, metadata)
        if metadata["runtimes-targets-1738"] then
            metadata["runtimes-targets-1832"] = metadata["runtimes-targets-1738"]
                                                    .map{|streamuuid|
                                                        NSXStreamsUtils::streamuuidToStreamDescriptionOrNull(streamuuid)
                                                    }
        end
        metadata
    end

end
