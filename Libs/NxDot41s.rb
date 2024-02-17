
# encoding: UTF-8

class NxDot41s

    # ------------------------------------
    # Makers

    # NxDot41s::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        payload = Px44::interactivelyMakeNewOrNull()

        node = {}
        node["uuid"] = uuid
        node["mikuType"] = "NxDot41"
        node["unixtime"] = Time.new.to_i
        node["datetime"] = Time.new.utc.iso8601
        node["description"] = description
        node["payload"] = payload
        node["linkeduuids"] = []
        node["notes"] = []
        node["tags"] = []

        NxDot41s::fsck(node)

        NxDot41s::commit(node)

        node
    end

    # ------------------------------------
    # Data

    # NxDot41s::toString(node)
    def self.toString(node)
        "#{node["description"]}#{Px44::toStringSuffix(node["payload"])}"
    end

    # NxDot41s::getOrNull(uuid)
    def self.getOrNull(uuid)
        nhash = Digest::SHA1.hexdigest(uuid)
        folderpath = "#{Config::pathToData()}/NxDot41"
        filepath = "#{folderpath}/#{nhash}.json"
        return nil if !File.exist?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxDot41s::commit(node)
    def self.commit(node)
        NxDot41s::fsck(node)
        nhash = Digest::SHA1.hexdigest(node["uuid"])
        folderpath = "#{Config::pathToData()}/NxDot41"
        filepath = "#{folderpath}/#{nhash}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(node)) }
    end

    # NxDot41s::items()
    def self.items()
        items = []
        Find.find("#{Config::pathToData()}/NxDot41") do |path|
            next if path[-5, 5] != '.json'
            items << JSON.parse(IO.read(path))
        end
        items
    end

    # ------------------------------------
    # Operations

    # NxDot41s::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = NxDot41s::getOrNull(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: "+node["description"].green
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"
            puts "- payload    : #{Px44::toStringSuffix(node["payload"])}"

            store = ItemStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNote::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| NxDot41s::getOrNull(id) }.compact
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
            puts "commands: select | description | access | payload | connect | disconnect | note | note remove | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                NxDot41s::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                node["description"] = description
                NxDot41s::commit(node)
                next
            end

            if command == "access" then
                Px44::access(node["payload"])
                next
            end

            if command == "payload" then
                url = LucilleCore::askQuestionAnswerAsString("url: ")
                next if url == ""
                payload = Px44::interactivelyMakeNewOrNull()
                next if payload.nil?
                node["payload"] = payload
                NxDot41s::commit(node)
                next
            end

            if command == "connect" then
                PolyFunctions::connect2(node)
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
                NxDot41s::commit(node)
                next
            end

            if command == "note remove" then
                puts "note remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                NxDot41s::destroy(node["uuid"])
                next
            end
        }

        nil
    end

    # NxDot41s::destroy(uuid)
    def self.destroy(uuid)
        nhash = Digest::SHA1.hexdigest(uuid)
        folderpath = "#{Config::pathToData()}/NxDot41"
        filepath = "#{folderpath}/#{nhash}.json"
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end

    # NxDot41s::fsck(item)
    def self.fsck(item)
        Px44::fsck(item["payload"])
    end
end
