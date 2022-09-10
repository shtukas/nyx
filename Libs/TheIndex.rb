# encoding: UTF-8

class TheIndex

    # create table _index_ (_objectuuid_ text primary key, _unixtime_ float, _mikuType_ text, _announce_ text, _item_ text)

    # -----------------------------------------------------------------
    # READ

    # TheIndex::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/theindex.sqlite3"
    end

    # TheIndex::objectuuids() # Array[objectuuid]
    def self.objectuuids()
        objectuuids = []
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _objectuuid_ from _index_", []) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # TheIndex::getItemOrNull(objectuuid)
    def self.getItemOrNull(objectuuid)
        item = nil
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _item_ from _index_ where _objectuuid_=?", [objectuuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # TheIndex::mikuTypeCount(mikuType) # Integer
    def self.mikuTypeCount(mikuType)
        count = nil
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from _index_ where _mikuType_=?", [mikuType]) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # TheIndex::mikuTypeToObjectuuids(mikuType) # Array[objectuuid]
    def self.mikuTypeToObjectuuids(mikuType)
        objectuuids = []
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _objectuuid_ from _index_ where _mikuType_=?", [mikuType]) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # TheIndex::mikuTypeToItems(mikuType) # Array[Item]
    def self.mikuTypeToItems(mikuType)
        items = []
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _item_ from _index_ where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # TheIndex::nx20s() # Array[Nx20]
    def self.nx20s()
        nx20s = []
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _index_", []) do |row|
            nx20s << {
                "announce" => "(#{row["_mikuType_"]}) #{row["_announce_"]}",
                "unixtime" => row["_unixtime_"],
                "item"     => JSON.parse(row["_item_"])
            }
        end
        db.close
        nx20s
    end

    # TheIndex::items() # Array[Item]
    def self.items()
        items = []
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _item_ from _index_", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # -----------------------------------------------------------------
    # WRITE

    # TheIndex::updateIndexAtObjectAttempt(objectuuid)
    def self.updateIndexAtObjectAttempt(objectuuid)
        item = DxF1::getProtoItemOrNull(objectuuid)
        return if item.nil?
        TheIndex::updateIndexWithThisObjectAttempt(item)
    end

    # TheIndex::updateIndexWithThisObjectAttempt(item)
    def self.updateIndexWithThisObjectAttempt(item)

       # create table _index_ (_objectuuid_ text primary key, _unixtime_ float, _mikuType_ text, _announce_ text, _item_ text)

        objectuuid = item["uuid"]
        unixtime   = item["unixtime"]
        mikuType   = item["mikuType"]

        return if objectuuid.nil?
        return if unixtime.nil?
        return if mikuType.nil?

        announce = PolyFunctions::genericDescription(item)

        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.execute "insert into _index_ (_objectuuid_, _unixtime_, _mikuType_, _announce_, _item_) values (?, ?, ?, ?, ?)", [objectuuid, unixtime, mikuType, announce, JSON.generate(item)]
        db.close
    end

    # TheIndex::updateIndexReadingDxF1s()
    def self.updateIndexReadingDxF1s()
        DxF1::dxF1sFilepathsEnumerator().each{|filepath|
            puts filepath
            item = DxF1::getProtoItemAtFilepathOrNull(filepath)
            next if item.nil?
            next if !item["isAlive"].nil? and !item["isAlive"]
            puts JSON.pretty_generate(item)
            TheIndex::updateIndexWithThisObjectAttempt(item)
        }
    end

    # TheIndex::destroy(objectuuid)
    def self.destroy(objectuuid)
        db = SQLite3::Database.new(TheIndex::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.close
    end
end
