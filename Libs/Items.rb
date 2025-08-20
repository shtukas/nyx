
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
            .select{|filepath| !File.basename(filepath).include?("sync-conflict") }
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

    # ------------------------------------------------------
    # Interface

    # Items::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        Items::filepaths().each{|filepath|
            entry = Items::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
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

    # Items::mikuType(mikuType)
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

    # ------------------------------------------------------
    # Operations

    # Items::maintenance()
    def self.maintenance()
        archive_filepath = "#{Items::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(Items::getDatabaseFilepath(), archive_filepath)
        end
    end
end