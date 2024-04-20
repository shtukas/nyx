
# encoding: UTF-8

class NxType1FileSystemNodes

    # ------------------------------------
    # Basic IO

    # NxType1FileSystemNodes::fsck(item)
    def self.fsck(item)

    end

    # NxType1FileSystemNodes::isFileSystemNode(filepath)
    def self.isFileSystemNode(filepath)
        b1 = File.basename(filepath)[-5, 5] == ".json"
        b2 = File.basename(filepath).include?(".nyx1-location.")
        b1 and b2
    end

    # NxType1FileSystemNodes::readUuidFromFilepath(filepath)
    def self.readUuidFromFilepath(filepath)
        object = JSON.parse(IO.read(filepath))
        if object["uuid"].nil? then
            raise "Could not determine uuid for file system node: #{filepath}"
        end
        object["uuid"]
    end

    # NxType1FileSystemNodes::getNodeExistingFilepathOrNull(uuid)
    def self.getNodeExistingFilepathOrNull(uuid)
        bruteforce = lambda{|uuid|
            Find.find("#{Config::userHomeDirectory()}/Galaxy") do |path|
                next if !NxType1FileSystemNodes::isFileSystemNode(path)
                next if NxType1FileSystemNodes::readUuidFromFilepath(path) != uuid
                return path
            end
            nil
        }

        filepath = XCache::getOrNull("0324d06f-1506:#{uuid}")
        if filepath and File.exist?(filepath) then
            return filepath
        end

        filepath = bruteforce.call(uuid)

        if filepath then
            XCache::set("0324d06f-1506:#{uuid}", filepath)
        end

        filepath
    end

    # NxType1FileSystemNodes::firstCommit(node)
    def self.firstCommit(node)
        NxType1FileSystemNodes::fsck(node)
        filename = "#{SecureRandom.hex(5)}.nyx1-location.#{SecureRandom.hex(2)}.json"
        folderpath1 = "#{Config::userHomeDirectory()}/Desktop"
        filepath = "#{folderpath1}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(node)) }
    end

    # NxType1FileSystemNodes::reCommit(node)
    def self.reCommit(node)
        filepath1 = NxType1FileSystemNodes::getNodeExistingFilepathOrNull(uuid)
        if filepath1.nil? then
            puts "I am trying to recommit this node (below) but I can't find the filepath"
            puts JSON.pretty_generate(node)
            raise "(error: ebaadd66)"
        end
        File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(node)) }
    end

    # ------------------------------------
    # Makers

    # NxType1FileSystemNodes::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (file system location) (empty to abort): ")
        return nil if description == ""

        node = {}
        node["uuid"] = uuid
        node["mikuType"] = "NxType1FileSystemNode"
        node["unixtime"] = Time.new.to_i
        node["datetime"] = Time.new.utc.iso8601
        node["description"] = description
        node["linkeduuids"] = []
        node["notes"] = []
        node["tags"] = []

        NxType1FileSystemNodes::fsck(node)

        NxType1FileSystemNodes::firstCommit(node)

        node
    end

    # ------------------------------------
    # Data

    # NxType1FileSystemNodes::toString(node)
    def self.toString(node)
        "📍 #{node["description"]}"
    end

    # NxType1FileSystemNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxType1FileSystemNodes::getNodeExistingFilepathOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NxType1FileSystemNodes::items()
    def self.items()

        getItemsFromScratch = lambda {
            items = []
            Find.find("#{Config::userHomeDirectory()}/Galaxy") do |path|
                next if !NxType1FileSystemNodes::isFileSystemNode(path)
                items << JSON.parse(IO.read(path))
            end
            items
        }

        getItemsUUIDsFromCachedIndexOrNull = lambda {
            items = XCache::getOrNull("2cc14521-a090-494f-86a8-47574525fdd4")
            return nil if items.nil?
            JSON.parse(items)
        }

        commitItemsUUIDsToCache = lambda {|items|
            XCache::set("2cc14521-a090-494f-86a8-47574525fdd4", JSON.generate(items))
        }

        uuids = getItemsUUIDsFromCachedIndexOrNull.call()
        if uuids then
            return uuids.map{|uuid| NxType1FileSystemNodes::getOrNull(uuid) }.compact
        end

        items = getItemsFromScratch.call()
        uuids = items.map{|item| item["uuid"] }
        commitItemsUUIDsToCache.call(uuids)

        items
    end

    # ------------------------------------
    # Operations

    # NxType1FileSystemNodes::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        NxType1FileSystemNodes::reCommit(node)
    end

    # NxType1FileSystemNodes::connect2(node)
    def self.connect2(node)
        node2 = PolyFunctions::architectNodeOrNull()
        return if node2.nil?
        NxType1FileSystemNodes::connect1(node, node2["uuid"])
        NxType1FileSystemNodes::connect1(node2, node["uuid"])
    end

    # NxType1FileSystemNodes::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = NxType1FileSystemNodes::getOrNull(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"

            store = ItemStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNote::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| NxType1FileSystemNodes::getOrNull(id) }.compact
            if linkednodes.size > 0 then
                puts ""
                puts "related nodes:"
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode, false)
                        puts "(#{store.prefixString()}) (node) #{linkednode["description"]}"
                    }
            end

            puts ""
            puts "commands: select | description | connect | disconnect | note | note remove | expose | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                NxType1FileSystemNodes::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                node["description"] = description
                NxType1FileSystemNodes::reCommit(node)
                next
            end

            if command == "connect" then
                NxType1FileSystemNodes::connect2(node)
                next
            end

            if command == "disconnect" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "note" then
                note = NxNote::interactivelyIssueNewOrNull()
                next if note.nil?
                node["notes"] << note
                NxType1FileSystemNodes::reCommit(node)
                next
            end

            if command == "note remove" then
                puts "note remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "expose" then
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                NxType1FileSystemNodes::destroy(node["uuid"])
                next
            end
        }

        nil
    end

    # NxType1FileSystemNodes::destroy(uuid)
    def self.destroy(uuid)
        puts "> request to destroy nyx node: #{uuid}"
        filepath1 = NxType1FileSystemNodes::getNodeExistingFilepathOrNull(uuid)
        return if filepath1.nil?
        FileUtils.rm(filepath)
    end
end
