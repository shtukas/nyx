
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

class Nx27

    # ------------------------------------------------------
    # Basic IO management

    # Nx27::directory()
    def self.directory()
        "#{Config::pathToData()}/databases/index3-items"
    end

    # Nx27::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Nx27::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .select{|filepath| !File.basename(filepath).include?("sync-conflict") }
    end

    # Nx27::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Nx27::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Nx27::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Nx27::directory()}/#{filename}"
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
        Nx27::ensureContentAddressing(filepath)
    end

    # Nx27::insertUpdateItemAtFile(filepath, item)
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
        Nx27::ensureContentAddressing(filepath)
    end

    # Nx27::removeEntryAtFile(filepath, uuid)
    def self.removeEntryAtFile(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.commit
        db.close
        Nx27::ensureContentAddressing(filepath)
    end

    # Nx27::extractEntryOrNullFromFilepath(filepath, uuid)
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

    # Nx27::insertUpdateEntryComponents2(filepath, utime, item)
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

    # Nx27::mergeTwoDatabaseFiles(filepath1, filepath2)
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        Nx27::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = Nx27::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
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
                Nx27::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        Nx27::ensureContentAddressing(filepath1)
    end

    # Nx27::extractEntriesFromFile(filepath)
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

    # Nx27::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Nx27::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            #return Nx27::initiateDatabaseFile()
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
            filepath1 = Nx27::mergeTwoDatabaseFiles(filepath1, filepath)
        }

        filepath1
    end

    # Nx27::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        Nx27::filepaths().each{|filepath|
            entry = Nx27::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
    end

    # ------------------------------------------------------
    # Interface

    # Nx27::init(uuid)
    def self.init(uuid)
        if Nx27::itemOrNull(uuid) then
            raise "(error: 0e16c053) this uuid is already in use, you cannot init it"
        end
        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx27",
          "datetime"    => Time.new.utc.iso8601,
          "description" => "Default description for initialised item. If you are reading this, something didn't happen",
          "px44s"       => [],
          "linkeduuids" => [],
          "notes"       => [],
          "tags"        => []
        }
        Nx27::commitItem(item)
    end

    # Nx27::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        entry = Nx27::entryOrNull(uuid)
        return nil if entry.nil?
        entry["item"]
    end

    # Nx27::commitItem(item)
    def self.commitItem(item)
        filepath = Nx27::getDatabaseFilepath()
        Nx27::insertUpdateItemAtFile(filepath, item)
    end

    # Nx27::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Nx27::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        Nx27::commitItem(item)
    end

    # Nx27::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(Nx27::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # Nx27::deleteItem(uuid)
    def self.deleteItem(uuid)
        Nx27::removeEntryAtFile(Nx27::getDatabaseFilepath(), uuid)
    end

    # Nx27::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ''
        px44 = Px44::interactivelyMakeNewOrNull(uuid)
        px44s = [px44].compact
        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx27",
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "px44s"       => px44s,
            "linkeduuids" => [],
            "notes"       => [],
            "tags"        => []
        }
        Nx27::commitItem(item)
        item
    end

    # Nx27::toString(node)
    def self.toString(node)
        "#{node["description"]}#{node["px44s"].map{|payload| Px44::toString(payload) }}"
    end

    # ------------------------------------------------------
    # Operations

    # Nx27::maintenance()
    def self.maintenance()
        archive_filepath = "#{Nx27::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(Nx27::getDatabaseFilepath(), archive_filepath)
        end
    end

    # Nx27::payloadProgram(node)
    def self.payloadProgram(node)
        loop {
            node = Nx27::itemOrNull(node["uuid"])
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
                Nx27::setAttribute(node["uuid"], "px44s", px44s)
            end
            if option == 'remove' then
                px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                next if px44.nil?
                px44s = px44s.reject{|i| i["uuid"] == px44["uuid"] }
                Nx27::setAttribute(node["uuid"], "px44s", px44s)
            end
        }
    end

    # Nx27::program(node, isSeekingSelect) # nil or node
    def self.program(node, isSeekingSelect)

        # isSeekingSelect: boolean
        # if isSeekingSelect is true, we are trying to identify a node, and in particular 
        # The caller will be paying attention to the return value.

        loop {

            node = Nx27::itemOrNull(node["uuid"])
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

            linkednodes = node["linkeduuids"].map{|id| Nx27::itemOrNull(id) }.compact
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
                Nx27::setAttribute(node["uuid"], "description",description)
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
                Nx27::payloadProgram(node)
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
                    Nx27::setAttribute(node["uuid"], "notes", node["notes"])
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
                Nx27::deleteItem(node["uuid"])
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
        if item["mikuType"] != 'Nx27' then
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
                Nx27::setAttribute(item["uuid"], "px44s", item["px44s"])
            end
        end
        item["px44s"].each{|px44|
            uuid = item["uuid"]
            Px44::fsck(uuid, px44)
        }
    end
end
