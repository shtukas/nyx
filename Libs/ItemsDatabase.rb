
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

class ItemsDatabase

    # ------------------------------------------------------
    # Basic IO management

    # ItemsDatabase::directory()
    def self.directory()
        "#{Config::pathToData()}/databases/index3-items"
    end

    # ItemsDatabase::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(ItemsDatabase::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .select{|filepath| !File.basename(filepath).include?("sync-conflict") }
    end

    # ItemsDatabase::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{ItemsDatabase::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # ItemsDatabase::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{ItemsDatabase::directory()}/#{filename}"
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
        ItemsDatabase::ensureContentAddressing(filepath)
    end

    # ItemsDatabase::insertUpdateItemAtFile(filepath, item)
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
        ItemsDatabase::ensureContentAddressing(filepath)
    end

    # ItemsDatabase::removeEntryAtFile(filepath, uuid)
    def self.removeEntryAtFile(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.commit
        db.close
        ItemsDatabase::ensureContentAddressing(filepath)
    end

    # ItemsDatabase::extractEntryOrNullFromFilepath(filepath, uuid)
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

    # ItemsDatabase::insertUpdateEntryComponents2(filepath, utime, item)
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

    # ItemsDatabase::mergeTwoDatabaseFiles(filepath1, filepath2)
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        ItemsDatabase::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = ItemsDatabase::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
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
                ItemsDatabase::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        ItemsDatabase::ensureContentAddressing(filepath1)
    end

    # ItemsDatabase::extractEntriesFromFile(filepath)
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

    # ItemsDatabase::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = ItemsDatabase::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            #return ItemsDatabase::initiateDatabaseFile()
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
            filepath1 = ItemsDatabase::mergeTwoDatabaseFiles(filepath1, filepath)
        }

        filepath1
    end

    # ItemsDatabase::insertUpdateItemAtFile(filepath, item)
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
        ItemsDatabase::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data

    # ItemsDatabase::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        ItemsDatabase::filepaths().each{|filepath|
            entry = ItemsDatabase::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
    end

    # ItemsDatabase::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        entry = ItemsDatabase::entryOrNull(uuid)
        return nil if entry.nil?
        entry["item"]
    end


    # ItemsDatabase::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(ItemsDatabase::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # ItemsDatabase::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(ItemsDatabase::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # ------------------------------------------------------
    # Operations

    # ItemsDatabase::commitItem(item)
    def self.commitItem(item)
        filepath = ItemsDatabase::getDatabaseFilepath()
        ItemsDatabase::insertUpdateItemAtFile(filepath, item)
    end

    # ItemsDatabase::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = ItemsDatabase::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        ItemsDatabase::commitItem(item)
    end

    # ItemsDatabase::deleteItem(uuid)
    def self.deleteItem(uuid)
        ItemsDatabase::removeEntryAtFile(ItemsDatabase::getDatabaseFilepath(), uuid)
    end

    # ItemsDatabase::maintenance()
    def self.maintenance()
        archive_filepath = "#{ItemsDatabase::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(ItemsDatabase::getDatabaseFilepath(), archive_filepath)
        end
    end
end