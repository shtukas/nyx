
class ItemsManager

    # ItemsManager::filepath1(foldername, uuid)
    def self.filepath1(foldername, uuid)
        "#{Config::pathToDataCenter()}/#{foldername}/#{uuid}.Nx5"
    end

    # ItemsManager::filepath2(foldername, uuid)
    def self.filepath2(foldername, uuid)
        "#{Config::pathToDataCenter()}/#{foldername}/#{uuid}.json"
    end

    # ItemsManager::items(foldername)
    def self.items(foldername)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{foldername}")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
            .map{|filepath|
                # We are doing this during the transition period
                filepath2 = filepath.gsub(".Nx5", "json")
                if File.exists?(filepath2) then
                    JSON.parse(IO.read(filepath2))
                else
                    Nx5Ext::readFileAsAttributesOfObject(filepath)
                end
            }
    end

    # ItemsManager::commit(foldername, item)
    def self.commit(foldername, item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = ItemsManager::filepath2(foldername, item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # ItemsManager::getOrNull(foldername, uuid)
    def self.getOrNull(foldername, uuid)
        filepath = ItemsManager::filepath1(foldername, uuid)
        filepath2 = filepath.gsub(".Nx5", ".json")
        if File.exists?(filepath2) then
            return JSON.parse(IO.read(filepath2))
        end
        if File.exists?(filepath) then
            return Nx5Ext::readFileAsAttributesOfObject(filepath)
        end
        nil
    end

    # ItemsManager::destroy(foldername, uuid)
    def self.destroy(foldername, uuid)
        filepath = ItemsManager::filepath1(foldername, uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        filepath2 = filepath.gsub(".Nx5", ".json")
        if File.exists?(filepath2) then
            FileUtils.rm(filepath2)
        end
        ItemToCx22::garbageCollection(uuid)
    end

    # ItemsManager::operatorForNx5(foldername, uuid)
    def self.operatorForNx5(foldername, uuid)
        filepath = ItemsManager::filepath1(foldername, uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end
end
