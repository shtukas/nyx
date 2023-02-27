
# encoding: UTF-8

class NightSkyIndex

    # NightSkyIndex::add_uuid_to_index(uuid)
    def self.add_uuid_to_index(uuid)
        File.open("#{Config::pathToNightSkyIndex()}/#{uuid}", "w"){|f| f.write(uuid) }
    end

    # NightSkyIndex::remove_uuid_from_index(uuid)
    def self.remove_uuid_from_index(uuid)
        indexFilepath = "#{Config::pathToNightSkyIndex()}/#{uuid}"
        return if !File.exist?(indexFilepath)
        FileUtils.rm("#{Config::pathToNightSkyIndex()}/#{uuid}")
    end
end
