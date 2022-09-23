# encoding: UTF-8

class Items

    # create table _index_ (_objectuuid_ text primary key, _unixtime_ float, _mikuType_ text, _announce_ text, _item_ text)

    # -----------------------------------------------------------------
    # READ

    # Items::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/items.sqlite3"
    end

    # Items::objectuuids() # Array[objectuuid]
    def self.objectuuids()
        objectuuids = []
        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _objectuuid_ from _index_", []) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # Items::getItemOrNull(objectuuid)
    def self.getItemOrNull(objectuuid)
        item = nil
        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _item_ from _index_ where _objectuuid_=?", [objectuuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Items::mikuTypeCount(mikuType) # Integer
    def self.mikuTypeCount(mikuType)
        count = nil
        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from _index_ where _mikuType_=?", [mikuType]) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # Items::mikuTypeToObjectuuids(mikuType) # Array[objectuuid]
    def self.mikuTypeToObjectuuids(mikuType)
        objectuuids = []
        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _objectuuid_ from _index_ where _mikuType_=?", [mikuType]) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # Items::mikuTypeToItems(mikuType) # Array[Item]
    def self.mikuTypeToItems(mikuType)
        items = []
        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _item_ from _index_ where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # Items::nx20s() # Array[Nx20]
    def self.nx20s()
        nx20s = []
        db = SQLite3::Database.new(Items::databaseFile())
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

    # Items::items() # Array[Item]
    def self.items()
        items = []
        db = SQLite3::Database.new(Items::databaseFile())
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

    # Items::updateIndexWithThisObjectAttempt(item)
    def self.updateIndexWithThisObjectAttempt(item)

        # create table _index_ (_objectuuid_ text primary key, _unixtime_ float, _mikuType_ text, _announce_ text, _item_ text)

        objectuuid = item["uuid"]
        unixtime   = item["unixtime"]
        mikuType   = item["mikuType"]

        return false if objectuuid.nil?
        return false if unixtime.nil?
        return false if mikuType.nil?

        announce = PolyFunctions::genericDescription(item)
        return false if announce.nil?

        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.execute "insert into _index_ (_objectuuid_, _unixtime_, _mikuType_, _announce_, _item_) values (?, ?, ?, ?, ?)", [objectuuid, unixtime, mikuType, announce, JSON.generate(item)]
        db.close

        true
    end

    # Items::updateIndexAtObjectAttempt(objectuuid)
    def self.updateIndexAtObjectAttempt(objectuuid)
        item = ItemsEventsLog::getProtoItemOrNull(objectuuid)
        return false if item.nil?
        Items::updateIndexWithThisObjectAttempt(item)
    end

    # Items::syncWithEventLog(verbose)
    def self.syncWithEventLog(verbose)
        objectuuidsFromTheEventLog = []
        ItemsEventsLog::objectuuids().each{|objectuuid|
            if verbose then
                puts "Items::syncWithEventLog(#{verbose}): objectuuid: #{objectuuid}"
            end
            status = Items::updateIndexAtObjectAttempt(objectuuid)
            if status then
                objectuuidsFromTheEventLog << objectuuid
            else
                # We remove from the index any object that doesn't validate
                Items::deleteObjectNoEvents(objectuuid)
            end
        }

        # We now remove from the index, the objects that are no longer in the event log
        Items::objectuuids().each{|objectuuid|
            next if objectuuidsFromTheEventLog.include?(objectuuid)
            Items::deleteObjectNoEvents(objectuuid)
        }
    end

    # Items::deleteObjectNoEvents(objectuuid)
    def self.deleteObjectNoEvents(objectuuid)
        db = SQLite3::Database.new(Items::databaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.close
    end
end
