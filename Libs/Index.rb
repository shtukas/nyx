
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

end
