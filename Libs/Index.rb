
# encoding: UTF-8

class Index

    # Index::commitItem(item)
    def self.commitItem(item)

        # Each item is stored in its own directory.
        # The directory name (and the path to it), are function of the 
        # item's uuid. 

        # The filename is function of the file contents

        # This insures that two versions of the same file are side by side in the 
        # same directory, which is going to be helpful to detect and resolve
        # conflicts

        uuid = item["uuid"]
        uuidhash = Digest::SHA1.hexdigest(uuid)
        directory = "#{Config::pathToNyxData()}/index/#{uuidhash[0, 2]}/#{uuidhash}"
        if !File.exist?(directory) then
            FileUtils.mkpath(directory)
        end
        filehash = Digest::SHA1.hexdigest(JSON.generate(item))
        filename = "#{filehash}.nyx-node-Nx23.json"
        filepath = "#{directory}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Index::getItems()
    def self.getItems()
        items = []
        root = "#{Config::pathToNyxData()}/index"
        Find.find(root) do |path|
            if path[-19, 19] == ".nyx-node-Nx23.json" then
                items << JSON.parse(IO.read(path))
            end
        end
        items
    end

    # Index::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        uuidhash = Digest::SHA1.hexdigest(uuid)
        directory = "#{Config::pathToNyxData()}/index/#{uuidhash[0, 2]}/#{uuidhash}"
        return nil if !File.exist?(directory)
        filepaths = LucilleCore::locationsAtFolder(directory)
                        .select{|filepath| filepath[-19, 19] == ".nyx-node-Nx23.json" }
        return nil if filepaths.empty?
        return JSON.parse(IO.read(filepaths[0])) if filepaths.size == 1
        # If we get to here, then we have two versions of the object
        puts "We have two version of the object at directory: #{directory}, now might be the moment to write that reconciliation code"
        raise "[error: 835e2057]"
    end

    # Index::init(uuid)
    def self.init(uuid)
        Index::commitItem({
            "uuid" => uuid,
            "mikuType" => "NxDeleted",
            "unixtime" => Time.new.to_i
        })
    end

    # Index::getMikuType(mikuType)
    def self.getMikuType(mikuType)
        items = []
        root = "#{Config::pathToNyxData()}/index"
        Find.find(root) do |path|
            if path[-19, 19] == ".nyx-node-Nx23.json" then
                item = JSON.parse(IO.read(path))
                if item["mikuType"] == mikuType then
                    items << item
                end
            end
        end
        items
    end

    # Index::deleteItem(uuid)
    def self.deleteItem(uuid)
        uuidhash = Digest::SHA1.hexdigest(uuid)
        directory = "#{Config::pathToNyxData()}/index/#{uuidhash[0, 2]}/#{uuidhash}"
        return if if !File.exist?(directory)
        LucilleCore::removeFileSystemLocation(directory)
    end
end
