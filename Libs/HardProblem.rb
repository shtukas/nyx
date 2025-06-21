
class HardProblem

    # -----------------------------------------------------------
    # Internals

    # HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
    def self.retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        return nil if !File.exist?(directory)
        filepaths = LucilleCore::locationsAtFolder(directory)
            .select{|filepath| filepath[-5, 5] == ".json" }
        if filepaths.size > 1 then
            filepaths.each{|filepath|
                FileUtils.rm(filepath)
            }
            return nil
        end
        filepaths[0]
    end

    # HardProblem::commitJsonDataToDiskContentAddressed(directory, data)
    def self.commitJsonDataToDiskContentAddressed(directory, data)
        if !File.exist?(directory) then
            FileUtils.mkpath(directory)
        end
        content = JSON.pretty_generate(data)
        filename = "#{Digest::SHA1.hexdigest(content)}.json"
        filepath = "#{directory}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(content) }
    end

    # HardProblem::retrieveUniqueJsonInDirectoryOrCacheTheLambda(directory, l)
    def self.retrieveUniqueJsonInDirectoryOrCacheTheLambda(directory, l)
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        if filepath then
            JSON.parse(IO.read(filepath))
        else
            data = l.call()
            HardProblem::commitJsonDataToDiskContentAddressed(directory, data)
            data
        end
    end

    # -----------------------------------------------------------
    # Interface

    # HardProblem::nodes()
    def self.nodes()
        directory = "#{Config::pathToData()}/HardProblem/items"
        l = lambda {
            Blades::items()
        }
        HardProblem::retrieveUniqueJsonInDirectoryOrCacheTheLambda(directory, l)
    end

    # HardProblem::nodeHasBeenCreated(item)
    def self.nodeHasBeenCreated(item)
        directory = "#{Config::pathToData()}/HardProblem/items"
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        return if filepath.nil?
        items = JSON.parse(IO.read(filepath)) + [item]
        FileUtils.rm(filepath)
        HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
    end

    # HardProblem::nodeHasBeenUpdated(itemuuid)
    def self.nodeHasBeenUpdated(itemuuid)
        item = Blades::getItemOrNull(itemuuid)
        return if item.nil?
        directory = "#{Config::pathToData()}/HardProblem/items"
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        return if filepath.nil?
        items = JSON.parse(IO.read(filepath))
        items = items.reject{|item| item["uuid"] == itemuuid }
        items = items + [item]
        FileUtils.rm(filepath)
        HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
    end

    # HardProblem::nodeHasBeenDestroyed(itemuuid)
    def self.nodeHasBeenDestroyed(itemuuid)
        directory = "#{Config::pathToData()}/HardProblem/items"
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        return if filepath.nil?
        items = JSON.parse(IO.read(filepath)).reject{|item| item["uuid"] == itemuuid }
        FileUtils.rm(filepath)
        HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
    end
end
