
# encoding: UTF-8

$InMemoryItems9ECED108 = nil

class Items

    # Items::getItemsFromDisk()
    def self.getItemsFromDisk()
        items = []
        root = "#{Config::pathToLibrary()}/items"
        Find.find(root) do |path|
            if path[-5, 5] == ".json" then
                items << JSON.parse(IO.read(path))
            end
        end
        items
    end

    # Items::ensureItemsInMemory()
    def self.ensureItemsInMemory()
        # This function just ensures that 
        if $InMemoryItems9ECED108.nil? then
            puts "loading items to memory".yellow
            $InMemoryItems9ECED108 = Items::getItemsFromDisk()
        end
    end

    # ---------------------------------------------

    # Items::commitItem(item)
    def self.commitItem(item)
        Fsck::fsckItem(item)
        filepath = "#{Config::pathToLibrary()}/items/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        if $InMemoryItems9ECED108 then
            $InMemoryItems9ECED108 = $InMemoryItems9ECED108.reject{|i| i["uuid"] == item["uuid"] } + [item]
        end
    end

    # Items::getItems()
    def self.getItems()
        Items::ensureItemsInMemory()
        $InMemoryItems9ECED108.clone()
    end

    # Items::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        Items::ensureItemsInMemory()
        $InMemoryItems9ECED108.select{|i| i["uuid"] == uuid }.first
    end

    # Items::init(uuid)
    def self.init(uuid)
        item = {
            "uuid" => uuid,
            "mikuType" => "NxDeleted",
            "unixtime" => Time.new.to_i
        }
        Items::commitItem(item)
        Items::ensureItemsInMemory()
        $InMemoryItems9ECED108 = $InMemoryItems9ECED108 + [item]
    end

    # Items::getMikuType(mikuType)
    def self.getMikuType(mikuType)
        Items::ensureItemsInMemory()
        $InMemoryItems9ECED108.select{|i| i["mikuType"] == mikuType }
    end

    # Items::setAttribute(uuid, attribute_name, attribute_value) -> UpdatedItem
    def self.setAttribute(uuid, attribute_name, attribute_value)
        item = Items::getItemOrNull(uuid)
        return nil if item.nil?
        item[attribute_name] = attribute_value
        Items::commitItem(item)
        item
    end

    # Items::deleteItem(uuid)
    def self.deleteItem(uuid)
        filepath = "#{Config::pathToLibrary()}/items/#{item["uuid"]}.json"
        if File.exist?(filepath) then
            FileUtils.rm(filepath)
        end
        if $InMemoryItems9ECED108 then
            $InMemoryItems9ECED108 = $InMemoryItems9ECED108.reject{|i| i["uuid"] == uuid }
        end
    end
end
