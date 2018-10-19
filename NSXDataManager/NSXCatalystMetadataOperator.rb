
# encoding: UTF-8

require "json"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# ----------------------------------------------------------------------------------

=begin
MetadataItem {
    "objectuuid" : UUID
    "uuid" # copy of objectuuid, used by Iphetra
    (other key value pairs)
}
=end

DATA_MANAGER_METADATA_IPHETRA_SETUUID = "abb5af8c-6dd8-466f-8198-c7cca62f8059"

class NSXCatalystMetadataOperator

    # NSXCatalystMetadataOperator::putItem(metadata)
    def self.putItem(metadata)
        metadata["uuid"] = metadata["objectuuid"] # for Iphetra
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, DATA_MANAGER_METADATA_IPHETRA_SETUUID, metadata)        
    end

    # NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
    def self.getMetadataForObject(objectuuid)
        newmetadata = {
            "objectuuid" => objectuuid
        }
        Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, DATA_MANAGER_METADATA_IPHETRA_SETUUID, objectuuid) || newmetadata
    end

    # NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    def self.setMetadataForObject(objectuuid, metadata)
        NSXCatalystMetadataOperator::putItem(metadata)
    end

    # NSXCatalystMetadataOperator::getAllMetadataObjects()
    def self.getAllMetadataObjects()
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, DATA_MANAGER_METADATA_IPHETRA_SETUUID)
    end

end

