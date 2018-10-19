
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

CATALYST_SYSTEM_DATA_IPHETRA_SETUUID = "e13183f1-4615-49a9-8862-b23a38783f26"

=begin
{
    "uuid"  => key,
    "value" => value
}
=end

class NSXSystemDataOperator

    # NSXSystemDataOperator::set(key, value)
    def self.set(key, value)
        object = {
            "uuid"  => key,
            "value" => value
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, CATALYST_SYSTEM_DATA_IPHETRA_SETUUID, object)
    end

    # NSXSystemDataOperator::getOrNull(key)
    def self.getOrNull(key)
        object = Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, CATALYST_SYSTEM_DATA_IPHETRA_SETUUID, key)
        return nil if object.nil?
        object["value"]
    end

    # NSXSystemDataOperator::getOrDefaultValue(key, defaultValue)
    def self.getOrDefaultValue(key, defaultValue)
        value = NSXSystemDataOperator::getOrNull(key)
        return value if value
        defaultValue
    end

    # NSXSystemDataOperator::destroy(key)
    def self.destroy(key)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, CATALYST_SYSTEM_DATA_IPHETRA_SETUUID, key)
    end

end


