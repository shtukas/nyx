
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

DATA_MANAGER_CATALYST_METADATA_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Manager/Catalyst-Metadata"
DATA_MANAGER_CATALYST_METADATA_V1_REPOSITORY_FOLDERPATH = "#{DATA_MANAGER_CATALYST_METADATA_REPOSITORY_FOLDERPATH}/metadata-v1"
$DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH = {}
=begin
Map[ObjectUUI, MetadataItem]
MetadataItem {
    "objectuuid" : UUID
    (other key value pairs)
}
=end
$DATA_MANAGER_CATALYST_METADATA_IO_SEMAPHORE = Mutex.new

class NSXCatalystMetadataOperator

    # NSXCatalystMetadataOperator::metadataV1FilePaths()
    def self.metadataV1FilePaths()
        filepaths = []
        Find.find(DATA_MANAGER_CATALYST_METADATA_V1_REPOSITORY_FOLDERPATH) do |path|
            next if !File.file?(path)
            next if path[-5,5] != ".json"
            filepaths << path
        end
        filepaths
    end

    # NSXCatalystMetadataOperator::metadataV1InitialLoadFromDisk()
    def self.metadataV1InitialLoadFromDisk()
        NSXCatalystMetadataOperator::metadataV1FilePaths()
            .each{|filepath|
                begin
                    metadata = JSON.parse(IO.read(filepath))
                    $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH[metadata["objectuuid"]] = metadata
                rescue
                end
            }
    end

    # NSXCatalystMetadataOperator::putItem(metadata)
    def self.putItem(metadata)
        filename = "#{Digest::SHA1.hexdigest(metadata["objectuuid"])}.json"
        folderpath = "#{DATA_MANAGER_CATALYST_METADATA_V1_REPOSITORY_FOLDERPATH}/#{filename[0,2]}/#{filename[2,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        File.open("#{folderpath}/#{filename}", "w"){|f| f.puts(JSON.pretty_generate(metadata)) }
        $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH[metadata["objectuuid"]] = metadata
    end

    # NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
    def self.getMetadataForObject(objectuuid)
        newmetadata = {
            "objectuuid" => objectuuid
        }
        ($DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH[objectuuid] || newmetadata).clone
    end

    # NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    def self.setMetadataForObject(objectuuid, metadata)
        NSXCatalystMetadataOperator::putItem(metadata)
    end

    # NSXCatalystMetadataOperator::getAllMetadataObjects()
    def self.getAllMetadataObjects()
        $DATA_MANAGER_CATALYST_METADATA_IN_MEMORY_HASH.values.map{|object| object.clone }
    end

end

puts "NSXCatalystMetadataOperator::metadataV1InitialLoadFromDisk()"
NSXCatalystMetadataOperator::metadataV1InitialLoadFromDisk()

