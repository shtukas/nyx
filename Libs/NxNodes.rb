
# encoding: UTF-8

class NxNodes

    # --------------------------------------
    # IO

    # NxNodes::filepath(uuid)
    def self.filepath(uuid)
        "#{Nyx::pathToNyx()}/Objects/#{uuid}.json"
    end

    # NxNodes::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Nyx::pathToNyx()}/Objects")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxNodes::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_NxNode(item, false)
        filepath = NxNodes::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxNodes::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxNodes::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxNodes::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # NxNodes::dataDirectoryPath(uuid)
    def self.dataDirectoryPath(uuid)
        "#{Nyx::pathToNyx()}/Data/#{uuid}"
    end

    # --------------------------------------
    # Makers

    # NxNodes::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
        }
        NxNodes::commit(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> make and access directory ? ") then
            NxNodes::accessNyxDirectory(uuid)
        end
        item
    end

    # --------------------------------------
    # Data

    # NxNodes::toString(item)
    def self.toString(item)
        "(node) #{item["description"]}"
    end

    # --------------------------------------
    # Ops

    # NxNodes::accessNyxDirectory(uuid)
    def self.accessNyxDirectory(uuid)
        folderpath = NxNodes::dataDirectoryPath(uuid)
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
    end

    # NxNodes::landing(item)
    def self.landing(item)
        loop {

            system('clear')

            puts NxNodes::toString(item).green

            store = ItemStore.new()

            puts ""
            linked = NxNetwork::linkednodes(item["uuid"])
            linked.each{|linkednode|
                store.register(linkednode, false)
                puts "- (#{store.prefixString()}) #{PolyFunctions::toString(linkednode)}"
            }

            puts ""
            puts "commands: access | link"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                linkednode = store.get(indx)
                next if linkednode.nil?
                NxNodes::landing(linkednode)
                next
            end

            if command == "access" then
                if !File.exists?(NxNodes::dataDirectoryPath(item["uuid"])) then
                    puts "data directory doesn't exist"
                    if LucilleCore::askQuestionAnswerAsBoolean("create and access data directory ? ") then
                        NxNodes::accessNyxDirectory(item["uuid"])
                    else
                        next
                    end
                end
                NxNodes::accessNyxDirectory(item["uuid"])
                next
            end

            if command == "link" then
                node2 = NxNodes::architectNodeOrNull()
                if node2 then
                    NxNetwork::link(item["uuid"], node2["uuid"])
                    NxNodes::landing(node2)
                end
                next
            end

        }
    end

    # NxNodes::interactivelySelectNodeOrNull()
    def self.interactivelySelectNodeOrNull()
        # This function is going to evolve as we get more nodes, but it's gonna do for the moment
        items = NxNodes::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("nodes", items, lambda{|item| NxNodes::toString(item) })
    end

    # NxNodes::architectNodeOrNull()
    def self.architectNodeOrNull()
        options = ["select || new", "new"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "select || new" then
            node = NxNodes::interactivelySelectNodeOrNull()
            if node then
                return node
            end
            return NxNodes::interactivelyIssueNewOrNull()
        end
        if option == "new" then
            return NxNodes::interactivelyIssueNewOrNull()
        end
        nil
    end

end
