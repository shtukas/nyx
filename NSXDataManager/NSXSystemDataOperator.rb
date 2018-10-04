
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

DATA_MANAGER_SYSTEM_DATA_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Manager/System-Data"
$DATA_MANAGER_SYSTEM_DATA_IN_MEMORY_HASH = {}

=begin
{
    "key"   => String
    "value" => Value
}
=end

class NSXSystemDataOperator

    # NSXSystemDataOperator::objectFilePaths()
    def self.objectFilePaths()
        filepaths = []
        Find.find(DATA_MANAGER_SYSTEM_DATA_REPOSITORY_FOLDERPATH) do |path|
            next if !File.file?(path)
            next if path[-5,5] != ".json"
            filepaths << path
        end
        filepaths
    end

    # NSXSystemDataOperator::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        NSXSystemDataOperator::objectFilePaths()
            .each{|filepath|
                begin
                    packet = JSON.parse(IO.read(filepath))
                    $DATA_MANAGER_SYSTEM_DATA_IN_MEMORY_HASH[packet["key"]] = packet["value"]
                rescue
                end
            }
    end

    # NSXSystemDataOperator::set(key, value)
    def self.set(key, value)
        packet = {
            "key"   => key,
            "value" => value
        }
        filename = "#{Digest::SHA1.hexdigest(key)}.json"
        folderpath = "#{DATA_MANAGER_SYSTEM_DATA_REPOSITORY_FOLDERPATH}/#{filename[0,2]}/#{filename[2,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        File.open("#{folderpath}/#{filename}", "w"){|f| f.puts(JSON.pretty_generate(packet)) }
        $DATA_MANAGER_SYSTEM_DATA_IN_MEMORY_HASH[key] = value
    end

    # NSXSystemDataOperator::getOrNull(key)
    def self.getOrNull(key)
        $DATA_MANAGER_SYSTEM_DATA_IN_MEMORY_HASH[key]
    end

    # NSXSystemDataOperator::getOrDefaultValue(key, defaultValue)
    def self.getOrDefaultValue(key, defaultValue)
        value = NSXSystemDataOperator::getOrNull(key)
        return value if value
        defaultValue
    end

    # NSXSystemDataOperator::destroy(key)
    def self.destroy(key)
        filename   = "#{Digest::SHA1.hexdigest(key)}.json"
        folderpath = "#{DATA_MANAGER_SYSTEM_DATA_REPOSITORY_FOLDERPATH}/#{filename[0,2]}/#{filename[2,2]}"
        filepath   = "#{folderpath}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
        $DATA_MANAGER_SYSTEM_DATA_IN_MEMORY_HASH.delete(key)
    end

end

NSXSystemDataOperator::initialLoadFromDisk()


