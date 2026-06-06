
# encoding: UTF-8

class Index

    # Index::location_is_nyx_node(location)
    def self.location_is_nyx_node(location)
        location[-19, 19] == ".nyx-node-Nx23.json"
    end

    # Index::reconcile(item1, item2)
    def self.reconcile(item1, item2)
        # This function is simple, we get two items and we return one
        item3 = {}
        keys3s = (item1.keys + item2.keys).uniq
        keys3s.each{|attribute|
            if JSON.generate(item1[attribute]) == JSON.generate(item2[attribute]) then
                item3[attribute] = item1[attribute]
            else
                loop {
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("value", [JSON.generate(item1[attribute]), JSON.generate(item2[attribute])])
                    next if option.nil?
                    item3[attribute] = JSON.parse(option)
                    break
                }
            end
        }
        item3
    end

    # Index::uuid_to_directory(uuid, should_create_if_missing)
    def self.uuid_to_directory(uuid, should_create_if_missing)
        uuidhash = Digest::SHA1.hexdigest(uuid)
        directory = "#{Config::pathToNyxData()}/index/#{uuidhash[0, 2]}/#{uuidhash}"
        if should_create_if_missing and !File.exist?(directory) then
            FileUtils.mkpath(directory)
        end
        directory
    end

    # Index::sendItemToDisk(item)
    def self.sendItemToDisk(item)
        filecontents = JSON.pretty_generate(item)
        filehash = Digest::SHA1.hexdigest(filecontents)
        filename = "#{filehash}.nyx-node-Nx23.json"
        directory = Index::uuid_to_directory(item["uuid"], true)
        filepath1 = "#{directory}/#{filename}"

        # We could just delete all existing filepaths and then write the new one
        # but I do not like the idea that the directory would be empty 
        # at some point in the process. So we are first writing the new file
        # (which may perfectly override an existing file if the two nodes
        # happned to have the same contents) and then, if any, we remove the 
        # one that was already there, if it's different from the one we just 
        # wrote

        filepaths_existing = LucilleCore::locationsAtFolder(directory)
                                .select{|location| Index::location_is_nyx_node(location) }

        File.open(filepath1, "w"){|f| f.puts(filecontents) }

        filepaths_to_delete = filepaths_existing.select{|f2| f2 != filepath1 }
        filepaths_to_delete.each{|f2|
            FileUtils.rm(f2)
        }
    end

    # We return an item, because it may not be the item that was submitted, in case we had to do a reconciliation
    # Index::commitItem(item) -> Item
    def self.commitItem(item)

        # Each item is stored in its own directory.
        # The directory name (and the path to it), are function of the 
        # item's uuid. 

        # The filename is function of the file contents

        # This insures that two versions of the same file are side by side in the 
        # same directory, which is going to be helpful to detect and resolve
        # conflicts

        # Before we write... 
        # Unless we are writing the first version, which is a NxDeleted
        # We are expecting that there will be a file in the directory. That's the 
        # previous version of the item/node.
        # If we find two file, then the assumption is that another nyx instance 
        # wrote it and we are just catching up
        # What we then do, is to write the item that just came in and then we 
        # need to do some reconciliation

        directory = Index::uuid_to_directory(item["uuid"], true)

        filepaths_existing = LucilleCore::locationsAtFolder(directory)
                                .select{|location| Index::location_is_nyx_node(location) }

        if filepaths_existing.size <= 1 then
            Index::sendItemToDisk(item)
            return item
        end

        reconciled = filepaths_existing.reduce(item){|accumulator, filepath|
            i = JSON.parse(IO.read(filepath))
            Index::reconcile(accumulator, i)
        }
        Index::sendItemToDisk(reconciled)
        reconciled
    end

    ## Index::getItemOrNull(uuid)
    #def self.getItemOrNull(uuid)
    #    uuidhash = Digest::SHA1.hexdigest(uuid)
    #    directory = "#{Config::pathToNyxData()}/index/#{uuidhash[0, 2]}/#{uuidhash}"
    #    return nil if !File.exist?(directory)
    #    filepaths = LucilleCore::locationsAtFolder(directory)
    #                    .select{|filepath| filepath[-19, 19] == ".nyx-node-Nx23.json" }
    #    return nil if filepaths.empty?
    #    return JSON.parse(IO.read(filepaths[0])) if filepaths.size == 1
    #    # If we get to here, then we have two versions of the object
    #    puts "We have two version of the object at directory: #{directory}, now might be the moment to write that reconciliation code"
    #    raise "[error: 835e2057]"
    #end

    ## Index::init(uuid)
    #def self.init(uuid)
    #    Index::commitItem({
    #        "uuid" => uuid,
    #        "mikuType" => "NxDeleted",
    #        "unixtime" => Time.new.to_i
    #    })
    #end

    ## Index::getMikuType(mikuType)
    #def self.getMikuType(mikuType)
    #    items = []
    #    root = "#{Config::pathToNyxData()}/index"
    #    Find.find(root) do |path|
    #        if path[-19, 19] == ".nyx-node-Nx23.json" then
    #            item = JSON.parse(IO.read(path))
    #            if item["mikuType"] == mikuType then
    #                items << item
    #            end
    #        end
    #    end
    #    items
    #end

    # Index::accessIndexNodeDirectory(uuid)
    def self.accessIndexNodeDirectory(uuid)
        uuidhash = Digest::SHA1.hexdigest(uuid)
        directory = "#{Config::pathToNyxData()}/index/#{uuidhash[0, 2]}/#{uuidhash}"
        if !File.exist?(directory) then
            puts "There is not directory for uuid: #{uuid}"
            puts "If there was one it would be at location: #{directory}"
            LucilleCore::pressEnterToContinue()
        end
        system("open '#{directory}'")
        LucilleCore::pressEnterToContinue()
    end

    # Index::deleteItem(uuid)
    def self.deleteItem(uuid)
        directory = directory = Index::uuid_to_directory(uuid, false)
        return if !File.exist?(directory)
        LucilleCore::removeFileSystemLocation(directory)
    end
end
