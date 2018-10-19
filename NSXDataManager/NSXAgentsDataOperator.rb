
# encoding: UTF-8

require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'json'

# ----------------------------------------------------------------------------------

CATALYST_AGENT_DATA_IPHETRA_SETUUID_PREFIX = "d0b1f843-324d-469e-80e6-b0f330491287"

=begin
{
    "uuid"  => key,
    "value" => value
}
=end

class NSXAgentsDataOperator

    # NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid)
    def self.agentuuidToSetUUID(agentuuid)
        "#{CATALYST_AGENT_DATA_IPHETRA_SETUUID_PREFIX}:#{agentuuid}"
    end

    # NSXAgentsDataOperator::set(agentuuid, key, value)
    def self.set(agentuuid, key, value)
        object = {
            "uuid"  => key,
            "value" => value
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid), object)        
    end

    # NSXAgentsDataOperator::getOrNull(agentuuid, key)
    def self.getOrNull(agentuuid, key)
        object = Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid), key)
        return nil if object.nil?
        object["value"]
    end

    # NSXAgentsDataOperator::getOrDefaultValue(agentuuid, key, defaultValue)
    def self.getOrDefaultValue(agentuuid, key, defaultValue)
        value = NSXAgentsDataOperator::getOrNull(agentuuid, key)
        return value if value
        defaultValue
    end

    # NSXAgentsDataOperator::destroy(agentuuid, key)
    def self.destroy(agentuuid, key)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, NSXAgentsDataOperator::agentuuidToSetUUID(agentuuid), key)
    end

end


