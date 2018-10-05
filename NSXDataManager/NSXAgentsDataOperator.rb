
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

DATA_MANAGER_AGENTS_DATA_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Manager/Agents-Data"
$DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH = {}

=begin
{
    "agentuuid" => String
    "key"        => String
    "value"      => Value
}
=end

class NSXAgentsDataOperator

    # NSXAgentsDataOperator::objectFilePaths()
    def self.objectFilePaths()
        filepaths = []
        Find.find(DATA_MANAGER_AGENTS_DATA_REPOSITORY_FOLDERPATH) do |path|
            next if !File.file?(path)
            next if path[-5,5] != ".json"
            filepaths << path
        end
        filepaths
    end

    # NSXAgentsDataOperator::initialLoadFromDisk()
    def self.initialLoadFromDisk()
        NSXAgentsDataOperator::objectFilePaths()
            .each{|filepath|
                begin
                    packet = JSON.parse(IO.read(filepath))
                    if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet["agentuuid"]].nil? then
                        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet["agentuuid"]] = {}
                    end
                    $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet["agentuuid"]][packet["key"]] = packet["value"]
                rescue
                end
            }
    end

    # NSXAgentsDataOperator::set(agentuuid, key, value)
    def self.set(agentuuid, key, value)
        packet = {
            "agentuuid" => agentuuid,
            "key"        => key,
            "value"      => value
        }
        filename = "#{Digest::SHA1.hexdigest(key)}.json"
        folderpath = "#{DATA_MANAGER_AGENTS_DATA_REPOSITORY_FOLDERPATH}/#{agentuuid}/#{filename[0,2]}/#{filename[2,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        File.open("#{folderpath}/#{filename}", "w"){|f| f.puts(JSON.pretty_generate(packet)) }
        if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid].nil? then
            $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid] = {}
        end        
        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid][key] = value
    end

    # NSXAgentsDataOperator::getOrNull(agentuuid, key)
    def self.getOrNull(agentuuid, key)
        return nil if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid].nil?
        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid][key]
    end

    # NSXAgentsDataOperator::getOrDefaultValue(agentuuid, key, defaultValue)
    def self.getOrDefaultValue(agentuuid, key, defaultValue)
        value = NSXAgentsDataOperator::getOrNull(agentuuid, key)
        return value if value
        defaultValue
    end

    # NSXAgentsDataOperator::destroy(agentuuid, key)
    def self.destroy(agentuuid, key)
        filename = "#{Digest::SHA1.hexdigest(key)}.json"
        folderpath = "#{DATA_MANAGER_AGENTS_DATA_REPOSITORY_FOLDERPATH}/#{agentuuid}/#{filename[0,2]}/#{filename[2,2]}"
        filepath = "#{folderpath}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
        return if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid].nil?
        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuid].delete(key)
    end

end

puts "NSXAgentsDataOperator::initialLoadFromDisk()"
NSXAgentsDataOperator::initialLoadFromDisk()

