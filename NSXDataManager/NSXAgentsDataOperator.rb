
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
    "agentuuuid" => String
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
                    if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet["agentuuuid"]].nil? then
                        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet["agentuuuid"]] = {}
                    end
                    $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet["agentuuuid"]][packet["key"]] = packet["value"]
                rescue
                end
            }
    end

    # NSXAgentsDataOperator::set(agentuuuid, key, value)
    def self.set(agentuuuid, key, value)
        packet = {
            "agentuuuid" => agentuuuid,
            "key"        => key,
            "value"      => value
        }
        filename = "#{Digest::SHA1.hexdigest(key)}.json"
        folderpath = "#{DATA_MANAGER_AGENTS_DATA_REPOSITORY_FOLDERPATH}/#{agentuuuid}/#{filename[0,2]}/#{filename[2,2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        File.open("#{folderpath}/#{filename}", "w"){|f| f.puts(JSON.pretty_generate(packet)) }
        if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet[agentuuuid]].nil? then
            $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[packet[agentuuuid]] = {}
        end        
        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuuid][key] = value.clone
    end

    # NSXAgentsDataOperator::getOrNull(agentuuuid, key)
    def self.getOrNull(agentuuuid, key)
        return nil if $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuuid].nil?
        $DATA_MANAGER_AGENTS_DATA_IN_MEMORY_HASH[agentuuuid][key].clone
    end

    # NSXAgentsDataOperator::getOrDefaultValue(agentuuuid, key, defaultValue)
    def self.getOrDefaultValue(agentuuuid, key, defaultValue)
        value = NSXAgentsDataOperator::getOrNull(agentuuuid, key)
        return value if value
        defaultValue
    end

end

NSXAgentsDataOperator::initialLoadFromDisk()

