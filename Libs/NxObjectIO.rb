
class NxObjectIO

    # NxObjectIO::allObjects()
    def self.allObjects()
        objects = []
        root = Config::pathToTheLibrarianObjects()
        Find.find(root) do |path|
            if path[-5, 5] == ".json" then
                objects << JSON.parse(IO.read(path))
            end
        end
        objects
    end

    # NxObjectIO::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        root = Config::pathToTheLibrarianObjects()
        Find.find(root) do |path|
            if path[-5, 5] == ".json" then
                object = JSON.parse(IO.read(path))
                return object if object["uuid"] == uuid
            end
        end
        nil
    end

    # NxObjectIO::identifyFilepathByObjectUUIDOrNull(uuid)
    def self.identifyFilepathByObjectUUIDOrNull(uuid)
        root = Config::pathToTheLibrarianObjects()
        Find.find(root) do |path|
            if path[-5, 5] == ".json" then
                object = JSON.parse(IO.read(path))
                return path if object["uuid"] == uuid
            end
        end
        nil
    end

    # NxObjectIO::commitObject(object) -> object (with updated random)
    def self.commitObject(object)
        filepathOld = NxObjectIO::identifyFilepathByObjectUUIDOrNull(object["uuid"])

        object["random"] = SecureRandom.hex(8) # this ensures that the object is going to be stored in a fresh filepath different from `filepath`

        # writing new object
        Fsck::fsckObject(object)
        contents = JSON.pretty_generate(object)
        hash1 = "SHA1-#{Digest::SHA1.hexdigest(contents)}"
        filepathNew = "#{Config::pathToTheLibrarianObjects()}/#{hash1}.json"
        puts "writing object at filepath: #{filepathNew}".yellow
        File.open(filepathNew, "w") {|f| f.puts(contents) }

        if filepathOld then
            # destroying existing
            puts "destroying filepath: #{filepathOld}".yellow
            FileUtils.rm(filepathOld)
        end

        object
    end

    # NxObjectIO::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxObjectIO::identifyFilepathByObjectUUIDOrNull(uuid)
        return if filepath.nil?
        puts "destroying filepath: #{filepath}".yellow
        FileUtils.rm(filepath)
    end
end
