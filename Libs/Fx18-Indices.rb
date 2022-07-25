
class Fx18Index2PrimaryLookup # (mikuType, objectuuid, announce, unixtime, item)

    # Fx18Index2PrimaryLookup::databaseFilepath()
    def self.databaseFilepath()
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/Fx18-Indices/index2.sqlite3"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        filepath
    end

    # Fx18Index2PrimaryLookup::buildIndexIfMissing()
    def self.buildIndexIfMissing()
        filepath = Fx18Index2PrimaryLookup::databaseFilepath()
        return if File.exists?(filepath)
        puts "building index2 database file"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _index_ (_mikuType_ text, _objectuuid_ text, _announce_ text, _unixtime_ float, _item_ text)"
        db.close

        Fx18::objectuuids().each{|objectuuid|
            Fx18Index2PrimaryLookup::updateIndexForObject(objectuuid)
        }
    end

    # Fx18Index2PrimaryLookup::rebuildIndex()
    def self.rebuildIndex()
        Fx18Index2PrimaryLookup::buildIndexIfMissing()

        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_"
        db.close

        Fx18::objectuuids().each{|objectuuid|
            Fx18Index2PrimaryLookup::updateIndexForObject(objectuuid)
        }
    end

    # Index Read Data ---------------------------------------------------------------------

    # Fx18Index2PrimaryLookup::filepaths()
    def self.filepaths()
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        filepaths = []
        db.execute("select * from _index_ order by _filepath_", []) do |row|
            filepaths << row["_filepath_"]
        end
        db.close
        filepaths
    end

    # Fx18Index2PrimaryLookup::mikuTypes()
    def self.mikuTypes()
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        mikuTypes = []
        db.execute("select * from _index_ order by _mikuType_", []) do |row|
            mikuTypes << row["_mikuType_"]
        end
        db.close
        mikuTypes.uniq
    end

    # Fx18Index2PrimaryLookup::objectuuids()
    def self.objectuuids()
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _index_", []) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # Fx18Index2PrimaryLookup::mikuType2objectuuids(mikuType)
    def self.mikuType2objectuuids(mikuType)
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _index_ where _mikuType_=?", [mikuType]) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # Fx18Index2PrimaryLookup::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        Fx18Index2PrimaryLookup::mikuType2objectuuids(mikuType).count
    end

    # Fx18Index2PrimaryLookup::countObjectsByMikuType(mikuType)
    def self.countObjectsByMikuType(mikuType)
        Fx18Index2PrimaryLookup::mikuType2objectuuids(mikuType).count
    end

    # Fx18Index2PrimaryLookup::nx20s()
    def self.nx20s()
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        nx20s = []
        db.execute("select * from _index_ order by _unixtime_", []) do |row|
            nx20s << {
                "announce"   => row["_announce_"],
                "unixtime"   => row["_unixtime_"],
                "objectuuid" => row["_objectuuid_"]
            }
        end
        db.close
        nx20s
    end

    # Fx18Index2PrimaryLookup::itemOrNull(objectuuid)
    def self.itemOrNull(objectuuid)
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        item = nil
        db.execute("select * from _index_ where _mikuType_=?", [mikuType]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Index Write Data ---------------------------------------------------------------------

    # Fx18Index2PrimaryLookup::updateIndexForObject(objectuuid)
    def self.updateIndexForObject(objectuuid)
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        puts "Fx18Index2PrimaryLookup::rebuildIndexData: objectuuid: #{objectuuid}"
        
        mikuType = Fx18Attributes::getOrNull(objectuuid, "mikuType")
        objectuuid = Fx18Attributes::getOrNull(objectuuid, "uuid")
        item = Fx18Utils::objectuuidToItemOrNull(objectuuid)
        return if item.nil?
        announce = "(#{mikuType}) #{LxFunction::function("generic-description", item)}"
        unixtime = item["datetime"] ? DateTime.parse(item["datetime"]).to_time.to_i : item["unixtime"]

        CommonUtils::putsOnPreviousLine("Fx18Index2PrimaryLookup::rebuildIndexData: objectuuid: #{objectuuid} ☑️")

        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.execute "insert into _index_ (_mikuType_, _objectuuid_, _announce_, _unixtime_, _item_) values (?, ?, ?, ?, ?)", [mikuType, objectuuid, announce, unixtime, JSON.generate(item)]
        db.close
    end

    # Fx18Index2PrimaryLookup::removeEntry(objectuuid)
    def self.removeEntry(objectuuid)
        Fx18Index2PrimaryLookup::buildIndexIfMissing()
        puts "Fx18Index2PrimaryLookup::removeEntry(#{objectuuid})"
        db = SQLite3::Database.new(Fx18Index2PrimaryLookup::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _index_ where _objectuuid_=?", [objectuuid]
        db.close
    end
end
