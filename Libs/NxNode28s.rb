
=begin
create table items (
    uuid text non null primary key,
    utime real non null,
    item text non null,
    mikuType text non null,
    description text non null
);
CREATE INDEX index1 ON items(uuid, mikuType);
=end

class NxNode28

    # ------------------------------------------------------
    # Basic IO management

    # NxNode28::directory()
    def self.directory()
        "#{Config::pathToData()}/databases/index3-items"
    end

    # NxNode28::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(NxNode28::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .select{|filepath| !File.basename(filepath).include?("sync-conflict") }
    end

    # NxNode28::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{NxNode28::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # NxNode28::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{NxNode28::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table items (
            uuid text non null primary key,
            utime real non null,
            item text non null,
            mikuType text non null,
            description text non null
        )", [])
        db.execute("CREATE INDEX items_index ON items(uuid, mikuType);", [])
        db.commit
        db.close
        NxNode28::ensureContentAddressing(filepath)
    end

    # NxNode28::insertUpdateItemAtFile(filepath, item)
    def self.insertUpdateItemAtFile(filepath, item)
        uuid = item["uuid"]
        utime = Time.new.to_f
        mikuType = item["mikuType"]
        description = item["description"]
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.execute("insert into items (uuid, utime, item, mikuType, description) values (?, ?, ?, ?, ?)", [uuid, utime, JSON.generate(item), mikuType, description])
        db.commit
        db.close
        NxNode28::ensureContentAddressing(filepath)
    end

    # NxNode28::removeEntryAtFile(filepath, uuid)
    def self.removeEntryAtFile(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.commit
        db.close
        NxNode28::ensureContentAddressing(filepath)
    end

    # NxNode28::extractEntryOrNullFromFilepath(filepath, uuid)
    def self.extractEntryOrNullFromFilepath(filepath, uuid)
        entry = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items where uuid=?", [uuid]) do |row|
            item = JSON.parse(row["item"])
            entry = {
                "uuid"        => row["uuid"],
                "utime"       => row["utime"],
                "item"        => JSON.parse(row["item"]),
                "mikuType"    => row["mikuType"],
                "description" => row["description"]
            }
        end
        db.close
        entry
    end

    # NxNode28::insertUpdateEntryComponents2(filepath, utime, item)
    def self.insertUpdateEntryComponents2(filepath, utime, item)
        mikuType = item["mikuType"]
        description = item["description"]
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [item["uuid"]])
        db.execute("insert into items (uuid, utime, item, mikuType, description) values (?, ?, ?, ?, ?)", [item["uuid"], utime, JSON.generate(item), mikuType, description])
        db.commit
        db.close
    end

    # NxNode28::mergeTwoDatabaseFiles(filepath1, filepath2)
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        NxNode28::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = NxNode28::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
            if entry1 then
                # We have entry1 and entry2
                # We perform the update if entry2 is newer than entry1
                if entry2["utime"] > entry1["utime"] then
                    shouldInject = true
                end
            else
                # entry1 is null, we inject entry2 into filepath1
                shouldInject = true
            end
            if shouldInject then
                NxNode28::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        NxNode28::ensureContentAddressing(filepath1)
    end

    # NxNode28::extractEntriesFromFile(filepath)
    def self.extractEntriesFromFile(filepath)
        entries = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            entries << {
                "uuid"        => row["uuid"],
                "utime"       => row["utime"],
                "item"        => JSON.parse(row["item"]),
                "mikuType"    => row["mikuType"],
                "description" => row["description"]
            }
        end
        db.close
        entries
    end

    # NxNode28::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = NxNode28::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            #return NxNode28::initiateDatabaseFile()
            raise "(error: 8dd2daa1)"
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        filepath1 = filepaths.shift
        filepaths.each{|filepath|
            # The logic here is to read the items from filepath2 and 
            # possibly add them to filepath1.
            # We get an updated filepath1 because of content addressing.
            filepath1 = NxNode28::mergeTwoDatabaseFiles(filepath1, filepath)
        }

        filepath1
    end

    # NxNode28::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        NxNode28::filepaths().each{|filepath|
            entry = NxNode28::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
    end

    # ------------------------------------------------------
    # Interface

    # NxNode28::init(uuid)
    def self.init(uuid)
        if NxNode28::itemOrNull(uuid) then
            raise "(error: 0e16c053) this uuid is already in use, you cannot init it"
        end
        item = {
          "uuid"        => uuid,
          "mikuType"    => "NxNode28",
          "datetime"    => Time.new.utc.iso8601,
          "description" => "Default description for initialised item. If you are reading this, something didn't happen",
          "px44s"       => [],
          "linkeduuids" => [],
          "notes"       => [],
          "tags"        => []
        }
        NxNode28::commitItem(item)
    end

    # NxNode28::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        entry = NxNode28::entryOrNull(uuid)
        return nil if entry.nil?
        entry["item"]
    end

    # NxNode28::commitItem(item)
    def self.commitItem(item)
        filepath = NxNode28::getDatabaseFilepath()
        NxNode28::insertUpdateItemAtFile(filepath, item)
    end

    # NxNode28::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = NxNode28::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        NxNode28::commitItem(item)
    end

    # NxNode28::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(NxNode28::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # NxNode28::mikuType(mikuType) -> Array[Item]
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(NxNode28::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # NxNode28::deleteItem(uuid)
    def self.deleteItem(uuid)
        NxNode28::removeEntryAtFile(NxNode28::getDatabaseFilepath(), uuid)
    end

    # NxNode28::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ''
        px44 = Px44::interactivelyMakeNewOrNull(uuid)
        px44s = [px44].compact
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxNode28",
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "px44s"       => px44s,
            "linkeduuids" => [],
            "notes"       => [],
            "tags"        => []
        }
        NxNode28::commitItem(item)
        item
    end

    # NxNode28::toString(node)
    def self.toString(node)
        "#{node["description"]}#{node["px44s"].map{|payload| Px44::toString(payload) }}"
    end

    # ------------------------------------------------------
    # Operations

    # NxNode28::maintenance()
    def self.maintenance()
        archive_filepath = "#{NxNode28::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(NxNode28::getDatabaseFilepath(), archive_filepath)
        end
    end

    # NxNode28::payloadProgram(node)
    def self.payloadProgram(node)
        loop {
            node = NxNode28::itemOrNull(node["uuid"])
            px44s = node["px44s"]
            puts "px44s (#{px44s.count} items):"
            px44s.each{|px44|
                puts "  - #{Px44::toString(px44)}"
            }
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull('option', ['access', 'add', 'remove'])
            break if option.nil?
            if option == 'access' then
                px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                next if px44.nil?
                Px44::access(node["uuid"], px44)
            end
            if option == 'add' then
                px44 = Px44::interactivelyMakeNewOrNull(node["uuid"])
                next if px44.nil?
                px44s << px44
                NxNode28::setAttribute(node["uuid"], "px44s", px44s)
            end
            if option == 'remove' then
                px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                next if px44.nil?
                px44s = px44s.reject{|i| i["uuid"] == px44["uuid"] }
                NxNode28::setAttribute(node["uuid"], "px44s", px44s)
            end
        }
    end

    # NxNode28::program(node, isSeekingSelect) # nil or node
    def self.program(node, isSeekingSelect)

        # isSeekingSelect: boolean
        # if isSeekingSelect is true, we are trying to identify a node, and in particular 
        # The caller will be paying attention to the return value.

        loop {

            node = NxNode28::itemOrNull(node["uuid"])
            break if node.nil?

            system('clear')

            if isSeekingSelect then
                puts " ---------------------------"
                puts "| select                    |"
                puts " ---------------------------"
            end

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- mikuType   : #{node["mikuType"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"
            puts "- px44s      :"
            node["px44s"].each{|payload|
                puts "    - #{Px44::toString(payload).strip}"
            }

            store = ItemStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| NxNode28::itemOrNull(id) }.compact
            if linkednodes.size > 0 then
                puts ""
                puts "related nodes:"
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode, false)
                        puts "(#{store.prefixString()}) (node) #{linkednode["description"]}"
                    }
            end

            if isSeekingSelect then
                puts ""
                puts "commands: #{"select".green} | description | access | payload | connect | disconnect | notes | expose | destroy"
            else
                puts ""
                puts "commands: description | access | payload | connect | disconnect | notes | expose | destroy"
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                node = PolyFunctions::program(item, isSeekingSelect)
                if node then
                    return node # was `select`ed
                end
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                NxNode28::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "access" then
                px44s = node["px44s"]
                loop {
                    px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                    break if px44.nil?
                    Px44::access(node["uuid"], px44)
                }
                next
            end

            if command == "payload" then
                NxNode28::payloadProgram(node)
                next
            end

            if command == "connect" then
                returned_node = PolyFunctions::connect2(node, isSeekingSelect)
                if returned_node then
                    return returned_node # was `select`ed
                end
                next
            end

            if command == "disconnect" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "notes" then
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["add new note", "remove note"])
                next if option.nil?
                if option == "add new note" then
                    note = NxNotes::interactivelyIssueNewOrNull()
                    next if note.nil?
                    node["notes"] << note
                    NxNode28::setAttribute(node["uuid"], "notes", node["notes"])
                end
                if option == "remove note" then
                    puts "note remove is not implemented yet"
                    LucilleCore::pressEnterToContinue()
                end
                next
            end

            if command == "expose" then
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                NxNode28::deleteItem(node["uuid"])
                next
            end
        }

        nil
    end

    # Item::fsckItem(item)
    def self.fsckNxNode(item)
        if item["uuid"].nil? then
            raise "item: #{JSON.pretty_generate(item)} is missing its uuid"
        end
        if item["mikuType"].nil? then
            raise "item: #{JSON.pretty_generate(item)} is missing its mikuType"
        end
        if item["mikuType"] != 'NxNode28' then
            raise "item: #{JSON.pretty_generate(item)} does not have the correct mikuType"
        end
        if item["description"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a description"
        end
        if item["datetime"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a datetime"
        end

        if item["linkeduuids"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a linkeduuids"
        end
        if item["linkeduuids"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s linkeduuids is not an array"
        end

        # TODO: fsck the notes
        if item["notes"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a notes"
        end
        if item["notes"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s notes is not an array"
        end
        item["notes"].each{|note|
            NxNotes::fsck(note)
        }

        # TODO: fsck the tags
        if item["tags"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a tags"
        end
        if item["tags"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s tags is not an array"
        end

        # TODO: fsck the px44s
        if item["px44s"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a px44s"
        end
        if item["px44s"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s px44s is not an array"
        end
        if item["px44s"].any?{|px44| px44.class.to_s != "Hash" } then
            puts "I have a node with what appears to be an incorrect px44s array"
            puts "node:"
            puts JSON.pretty_generate(item)
            if LucilleCore::askQuestionAnswerAsBoolean("Should I repair the array by discarding the non hash elements ? ") then
                item["px44s"] = item["px44s"].select{|element| element.class.to_s == "Hash" }
                puts "node (updated):"
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                NxNode28::setAttribute(item["uuid"], "px44s", item["px44s"])
            end
        end
        item["px44s"].each{|px44|
            uuid = item["uuid"]
            Px44::fsck(uuid, px44)
        }
    end
end
