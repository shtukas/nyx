
class ItemsManager

    # ItemsManager::filepath(foldername, uuid)
    def self.filepath(foldername, uuid)
        "#{Config::pathToDataCenter()}/#{foldername}/#{uuid}.json"
    end

    # ItemsManager::items(foldername)
    def self.items(foldername)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{foldername}")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # ItemsManager::commit(foldername, item)
    def self.commit(foldername, item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = ItemsManager::filepath(foldername, item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # ItemsManager::getOrNull(foldername, uuid)
    def self.getOrNull(foldername, uuid)
        filepath = ItemsManager::filepath(foldername, uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # ItemsManager::destroy(foldername, uuid)
    def self.destroy(foldername, uuid)
        filepath = ItemsManager::filepath(foldername, uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        ItemToCx22::garbageCollection(uuid)
    end
end
