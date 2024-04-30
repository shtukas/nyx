
# encoding: UTF-8

class NxType3NavigationNodesIndex

    # NxType3NavigationNodesIndex::getItemsFromScratch()
    def self.getItemsFromScratch()
        items = []
        Find.find("#{Config::userHomeDirectory()}/Galaxy") do |path|
            next if !NxType3NavigationNodes::isNavigationNode(path)
            items << JSON.parse(IO.read(path))
        end
        items
    end

    # NxType3NavigationNodesIndex::getUUIDsFromCachedIndexOrNull()
    def self.getUUIDsFromCachedIndexOrNull()
        items = XCache::getOrNull("5a402c08-664f-4fbc-87df-2cc4a088e399")
        return nil if items.nil?
        JSON.parse(items)
    end

    # NxType3NavigationNodesIndex::commitUUIDsToCache(uuids)
    def self.commitUUIDsToCache(uuids)
        XCache::set("5a402c08-664f-4fbc-87df-2cc4a088e399", JSON.generate(uuids))
    end

    # NxType3NavigationNodesIndex::updateCacheWithNewUUID(uuid)
    def self.updateCacheWithNewUUID(uuid)
        uuids = XCache::getOrNull("5a402c08-664f-4fbc-87df-2cc4a088e399")
        uuids = 
            if uuids.nil? then
                []
            else
                JSON.parse(uuids)
            end
        uuids = uuids + [uuid]
        XCache::set("5a402c08-664f-4fbc-87df-2cc4a088e399", JSON.generate(uuids))
    end

    # NxType3NavigationNodesIndex::rebuildCacheFromScratch()
    def self.rebuildCacheFromScratch()
        uuids = NxType3NavigationNodesIndex::getItemsFromScratch().map{|item| item["uuid"] }
        NxType3NavigationNodesIndex::commitUUIDsToCache(uuids)
    end
end

class NxType3NavigationNodes

    # ------------------------------------
    # Basic IO

    # NxType3NavigationNodes::fsck(item)
    def self.fsck(item)
    end

    # NxType3NavigationNodes::isNavigationNode(filepath)
    def self.isNavigationNode(filepath)
        b1 = File.basename(filepath)[-5, 5] == ".json"
        b2 = File.basename(filepath).include?(".nyx3-navigation.")
        b1 and b2
    end

    # NxType3NavigationNodes::getUuidFromNavigationNode(filepath)
    def self.getUuidFromNavigationNode(filepath)
        object = JSON.parse(IO.read(filepath))
        if object["uuid"].nil? then
            raise "Could not determine uuid for navigation node: #{filepath}"
        end
        object["uuid"]
    end

    # NxType3NavigationNodes::getNodeExistingFilepathOrNull(uuid)
    def self.getNodeExistingFilepathOrNull(uuid)
        coresearch = lambda {|uuid|
            Find.find("#{Config::userHomeDirectory()}/Galaxy") do |path|
                next if !NxType3NavigationNodes::isNavigationNode(path)
                next if NxType3NavigationNodes::getUuidFromNavigationNode(path) != uuid
                return path
            end
            nil
        }

        filepath = XCache::getOrNull("088b8b0f-8003:#{uuid}")
        if filepath and File.exist?(filepath) then
            return filepath
        end

        filepath = coresearch.call(uuid)

        if filepath then
            XCache::set("088b8b0f-8003:#{uuid}", filepath)
        end

        filepath
    end

    # NxType3NavigationNodes::firstCommit(node)
    def self.firstCommit(node)
        NxType3NavigationNodes::fsck(node)
        filename = "#{SecureRandom.hex(5)}.nyx3-navigation.#{SecureRandom.hex(2)}.json"
        folderpath1 = "#{Config::userHomeDirectory()}/Galaxy/Timeline/2024/2024-04-NyxNodes"
        if !File.exist?(folderpath1) then
            FileUtils.mkpath(folderpath1)
        end
        folderpath2 = LucilleCore::indexsubfolderpath(folderpath1)
        filepath = "#{folderpath2}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(node)) }

        # ----------------------------------------------------------------------
        # We now update the cache with a new uuid

        NxType3NavigationNodesIndex::updateCacheWithNewUUID(node["uuid"])
        # ----------------------------------------------------------------------
    end

    # NxType3NavigationNodes::reCommit(node)
    def self.reCommit(node)
        filepath1 = NxType3NavigationNodes::getNodeExistingFilepathOrNull(node["uuid"])
        if filepath1.nil? then
            puts "I am trying to recommit this node (below) but I can't find the filepath"
            puts JSON.pretty_generate(node)
            raise "(error: 2d1eead4)"
        end
        File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(node)) }
    end

    # ------------------------------------
    # Makers

    # NxType3NavigationNodes::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (navigation) (empty to abort): ")
        return nil if description == ""

        node = {}
        node["uuid"] = uuid
        node["mikuType"] = "NxType3NavigationNode"
        node["unixtime"] = Time.new.to_i
        node["datetime"] = Time.new.utc.iso8601
        node["description"] = description
        node["linkeduuids"] = []
        node["notes"] = []
        node["tags"] = []

        NxType3NavigationNodes::fsck(node)

        NxType3NavigationNodes::firstCommit(node)

        node
    end

    # ------------------------------------
    # Data

    # NxType3NavigationNodes::toString(node)
    def self.toString(node)
        "🧭 #{node["description"]}"
    end

    # NxType3NavigationNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxType3NavigationNodes::getNodeExistingFilepathOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NxType3NavigationNodes::items()
    def self.items()
        uuids = NxType3NavigationNodesIndex::getUUIDsFromCachedIndexOrNull()
        if uuids then
            return uuids.map{|uuid| NxType3NavigationNodes::getOrNull(uuid) }.compact
        end
        items = NxType3NavigationNodesIndex::getItemsFromScratch()
        uuids = items.map{|item| item["uuid"] }
        NxType3NavigationNodesIndex::commitUUIDsToCache(uuids)
        items
    end

    # ------------------------------------
    # Operations

    # NxType3NavigationNodes::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = NxType3NavigationNodes::getOrNull(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- mikuType   : #{node["mikuType"].green}"
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

            linkednodes = node["linkeduuids"].map{|id| NyxNodesGI::getOrNull(id) }.compact
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
                NyxNodesGI::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                node["description"] = description
                NxType3NavigationNodes::reCommit(node)
                next
            end

            if command == "connect" then
                NyxNodesGI::connect2(node)
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
                NxType3NavigationNodes::reCommit(node)
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
                NxType3NavigationNodes::destroy(node["uuid"])
                next
            end
        }

        nil
    end

    # NxType3NavigationNodes::destroy(uuid)
    def self.destroy(uuid)
        puts "> request to destroy nyx node: #{uuid}"
        filepath1 = NxType3NavigationNodes::getNodeExistingFilepathOrNull(uuid)
        return if filepath1.nil?
        FileUtils.rm(filepath1)
    end
end
