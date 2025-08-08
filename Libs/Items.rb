
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

class Items

    # ------------------------------------------------------
    # Basic IO management

    # Items::directory()
    def self.directory()
        "#{Config::pathToData()}/databases/index3-items"
    end

    # Items::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Items::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Items::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Items::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Items::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Items::directory()}/#{filename}"
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
        Items::ensureContentAddressing(filepath)
    end

    # Items::insertUpdateItemAtFile(filepath, item)
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
        Items::ensureContentAddressing(filepath)
    end

    # Items::removeEntryAtFile(filepath, uuid)
    def self.removeEntryAtFile(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.commit
        db.close
        Items::ensureContentAddressing(filepath)
    end

    # Items::extractEntryOrNullFromFilepath(filepath, uuid)
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

    # Items::insertUpdateEntryComponents2(filepath, utime, item)
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

    # Items::mergeTwoDatabaseFiles(filepath1, filepath2)
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        Items::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = Items::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
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
                Items::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        Items::ensureContentAddressing(filepath1)
    end

    # Items::extractEntriesFromFile(filepath)
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

    # Items::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Items::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            #return Items::initiateDatabaseFile()
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
            filepath1 = Items::mergeTwoDatabaseFiles(filepath1, filepath)
        }

        filepath1
    end

    # Items::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        Items::filepaths().each{|filepath|
            entry = Items::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
    end

    # ------------------------------------------------------
    # Interface

    # Items::init(uuid)
    def self.init(uuid)
        if Items::itemOrNull(uuid) then
            raise "(error: 0e16c053) this uuid is already in use, you cannot init it"
        end
        item = {
          "uuid"        => uuid,
          "mikuType"    => "NxNode28",
          "datetime"    => Time.new.utc.iso8601,
          "description" => "Default description for initialised item. If you are reading this, something didn't happen",
          "payloads"    => [],
          "linkeduuids" => [],
          "notes"       => [],
          "tags"        => []
        }
        Items::commitItem(item)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        entry = Items::entryOrNull(uuid)
        return nil if entry.nil?
        entry["item"]
    end

    # Items::commitItem(item)
    def self.commitItem(item)
        filepath = Items::getDatabaseFilepath()
        Items::insertUpdateItemAtFile(filepath, item)
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Items::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        Items::commitItem(item)
    end

    # Items::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(Items::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # Items::mikuType(mikuType) -> Array[Item]
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(Items::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # Items::deleteItem(uuid)
    def self.deleteItem(uuid)
        Items::removeEntryAtFile(Items::getDatabaseFilepath(), uuid)
    end

    # Items::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ''
        payload = Px44::interactivelyMakeNewOrNull(uuid)
        payloads    = [payload].compact
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxNode28",
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "payloads"    => payloads,
            "linkeduuids" => [],
            "notes"       => [],
            "tags"        => []
        }
        Items::commitItem(item)
        item
    end

    # Items::toString(node)
    def self.toString(node)
        "#{node["description"]}#{node["payloads"].map{|payload| Px44::toString(payload) }}"
    end

    # ------------------------------------------------------
    # Operations

    # Items::maintenance()
    def self.maintenance()
        archive_filepath = "#{Items::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(Items::getDatabaseFilepath(), archive_filepath)
        end
    end

    # Items::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = Items::itemOrNull(node["uuid"])
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
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| Items::itemOrNull(id) }.compact
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
                Items::setAttribute(node["uuid"], "description",description)
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
                Items::setAttribute(node["uuid"], "payloads", node["payloads"])
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
                note = NxNotes::interactivelyIssueNewOrNull()
                next if note.nil?
                node["notes"] << note
                Items::setAttribute(node["uuid"], "notes", node["notes"])
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
                Items::deleteItem(node["uuid"])
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

        # TODO: fsck the payloads
        if item["payloads"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a payloads"
        end
        if item["payloads"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s payloads is not an array"
        end
        if item["payloads"].any?{|px44| px44.class.to_s != "Hash" } then
            puts "I have a node with what appears to be an incorrect payloads array"
            puts "node:"
            puts JSON.pretty_generate(item)
            if LucilleCore::askQuestionAnswerAsBoolean("Should I repair the array by discarding the non hash elements ? ") then
                item["payloads"] = item["payloads"].select{|element| element.class.to_s == "Hash" }
                puts "node (updated):"
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                Items::setAttribute(item["uuid"], "payloads", item["payloads"])
            end
        end
        item["payloads"].each{|px44|
            uuid = item["uuid"]
            Px44::fsck(uuid, px44)
        }
    end
end
