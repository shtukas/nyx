
class NxNode28s

    # -----------------------------------------------------------------
    # Disk Encoding/Decoding

    # NxNode28s::nodefiles_filepaths_enumeration()
    def self.nodefiles_filepaths_enumeration()
        root = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/NxNode28s"
        Enumerator.new do |filepaths|
            Find.find(root) do |path|
                if File.basename(path)[-4, 4] == ".txt" then
                    filepaths << path
                end
            end
        end
    end

    # NxNode28s::readUUIDFromFile(filepath)
    def self.readUUIDFromFile(filepath)
        text = IO.read(filepath).strip
        lines = text.lines.map{|line| line.strip }
        ls = lines.select{|line| line.start_with?('uuid:') }
        if ls.size == 0 then
            raise "the file at '#{filepath}' doesn't seem to have a uuid 🤔"
        end
        if ls.size > 1 then
            raise "the file at '#{filepath}' seems to have more than one uuids 🤔"
        end
        line = ls.first
        line[5, line.size].strip
    end

    # NxNode28s::filepathForUUIDOrNull(uuid)
    def self.filepathForUUIDOrNull(uuid)
        filepaths = NxNode28s::nodefiles_filepaths_enumeration().select{|filepath| NxNode28s::readUUIDFromFile(filepath) == uuid }
        if filepaths.size == 0 then
            return nil
        end
        if filepaths.size > 1 then
            puts "found several files for uuid: #{uuid}"
            puts JSON.pretty_generate(filepaths)
            raise "^ 🤔"
        end
        filepaths.first
    end

    # NxNode28s::newFilePath()
    def self.newFilePath()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/NxNode28s/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{CommonUtils::timeStringL22()}.txt"
    end

    # NxNode28s::attributesToNodeFileText(node28)
    def self.attributesToNodeFileText(node28)
        [
            "uuid: #{node28["uuid"]}",
            "mikuType: NxNode28",
            "description: #{node28["description"]}",
            "datetime: #{node28["datetime"]}",
            node28["linkeduuids"].map{|uuid|
                "linkeduuid: #{uuid}"
            },
            node28["notes"].map{|note|
                "note: #{JSON.generate(note)}"
            },
            node28["tags"].map{|tag|
                "tag: #{tag}"
            },
            node28["payloads"].map{|payload|
                "payload: #{JSON.generate(payload)}"
            },
        ]
            .flatten
            .join("\n")
    end

    # NxNode28s::commitItemToDisk(node28)
    def self.commitItemToDisk(node28)
        NxNode28s::fsckNxNode28(node28)
        text = NxNode28s::attributesToNodeFileText(node28)
        filepath1 = NxNode28s::filepathForUUIDOrNull(node28["uuid"])
        filepath2 = filepath1 || NxNode28s::newFilePath()
        File.open(filepath2, "w"){|f| f.puts(text) }
    end

    # NxNode28s::loadItemFromDisk(filepath)
    def self.loadItemFromDisk(filepath)
        node28 = {}

        node28["uuid"]        = nil
        node28["mikuType"]    = nil
        node28["datetime"]    = nil
        node28["description"] = nil

        node28["payloads"]    = []
        node28["linkeduuids"] = []
        node28["notes"]       = []
        node28["tags"]        = []

        text = IO.read(filepath).strip
        text.lines.each{|line|
            line  = line.strip
            i     = line.index(':')
            key   = line[0, i].strip
            value = line[i+1, line.size].strip

            if key == "uuid" then
                node28["uuid"] = value
                next
            end
            if key == "mikuType" then
                node28["mikuType"] = value
                next
            end
            if key == "datetime" then
                node28["datetime"] = value
                next
            end
            if key == "datetime" then
                node28["datetime"] = value
                next
            end
            if key == "description" then
                node28["description"] = value
                next
            end
            if key == "payload" then
                node28["payloads"] << JSON.parse(value)
                next
            end
            if key == "linkeduuid" then
                node28["linkeduuids"] << value
                next
            end
            if key == "note" then
                node28["notes"] << JSON.parse(value)
                next
            end
            if key == "tag" then
                node28["tags"] << JSON.parse(value)
                next
            end
        }

        node28
    end

    # -----------------------------------------------------------------
    # Main Interface

    # NxNode28s::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = NxNode28s::filepathForUUIDOrNull(uuid)
        return nil if filepath.nil?
        node28 = NxNode28s::loadItemFromDisk(filepath)
        NxNode28s::fsckNxNode28(node28)
        node28
    end

    # NxNode28s::items()
    def self.items()
        NxNode28s::nodefiles_filepaths_enumeration()
            .map{|filepath| NxNode28s::loadItemFromDisk(filepath) }
    end

    # NxNode28s::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxNode28s::filepathForUUIDOrNull(uuid)
        return nil if filepath.nil?
        FileUtils.rm(filepath)
    end

    # NxNode28s::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = NxNode28s::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        NxNode28s::commitItemToDisk(item)
    end

    # NxNode28s::toString(node)
    def self.toString(node)
        "#{node["description"]}#{node["payloads"].map{|payload| Px44::toString(payload) }}"
    end

    # NxNode28s::fsckNxNode28(node28)
    def self.fsckNxNode28(node28)
        if node28["uuid"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} is missing its uuid"
        end
        if node28["mikuType"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} is missing its mikuType"
        end
        if node28["mikuType"] != 'NxNode28' then
            raise "node28: #{JSON.pretty_generate(node28)} does not have the correct mikuType"
        end
        if node28["description"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a description"
        end
        if node28["datetime"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a datetime"
        end

        if node28["linkeduuids"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a linkeduuids"
        end
        if node28["linkeduuids"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s linkeduuids is not an array"
        end

        # TODO: fsck the notes
        if node28["notes"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a notes"
        end
        if node28["notes"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s notes is not an array"
        end
        node28["notes"].each{|note|
            NxNote::fsck(note)
        }

        # TODO: fsck the tags
        if node28["tags"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a tags"
        end
        if node28["tags"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s tags is not an array"
        end

        # TODO: fsck the payloads
        if node28["payloads"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a payloads"
        end
        if node28["payloads"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s payloads is not an array"
        end
        node28["payloads"].each{|px44|
            uuid = node28["uuid"]
            Px44::fsck(uuid, px44)
        }
    end

    # NxNode28s::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        uuid        = SecureRandom.uuid
        mikuType    = "NxNode28"
        datetime    = Time.new.utc.iso8601
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        if description == '' then
            return nil
        end
        payloads    = [Px44::interactivelyMakeNewOrNull(uuid)].compact
        linkeduuids = []
        notes       = []
        tags        = []
        {
            "uuid"        => uuid,
            "mikuType"    => "NxNode28",
            "datetime"    => datetime,
            "description" => description,
            "payloads"    => payloads,
            "linkeduuids" => linkeduuids,
            "notes"       => notes,
            "tags"        => tags
        }
    end

    # NxNode28s::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        node28 = NxNode28s::interactivelyMakeNewOrNull()
        return nil if node28.nil?
        NxNode28s::commitItemToDisk(node28)
    end

    # NxNode28s::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = NxNode28s::itemOrNull(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- mikuType   : #{node["mikuType"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"
            puts "- payloads   :"
            node["payloads"].each{|payload|
                puts "    - #{Px44::toString(payload).strip}"
            }

            store = ItemStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNote::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| NxNode28s::itemOrNull(id) }.compact
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
            puts "commands: select | description | access | payloads | connect | disconnect | note | note remove | expose | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                PolyFunctions::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                NxNode28s::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "access" then
                node["payloads"].each{|payload|
                    Px44::access(node["uuid"], payload)
                }
                next
            end

            if command == "payloads" then
                payload = Px44::interactivelyMakeNewOrNull(node["uuid"])
                next if payload.nil?
                node["payloads"] << payload
                NxNode28s::setAttribute(node["uuid"], "payloads", node["payloads"])
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
                NxNode28s::setAttribute(node["uuid"], "notes", node["notes"])
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
                NxNode28s::destroy(node["uuid"])
                next
            end
        }

        nil
    end
end
