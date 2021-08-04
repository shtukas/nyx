
# encoding: UTF-8

class CatalystDatabase

    # CatalystDatabase::databaseFilepath()
    def self.databaseFilepath()
        "#{Utils::catalystDataCenterFolderpath()}/catalyst.sqlite3"
    end

    # CatalystDatabase::insertRecord(uuid, unixtime, description, catalystType, payload1, payload2, payload3)
    def self.insertRecord(uuid, unixtime, description, catalystType, payload1, payload2, payload3)
        db = SQLite3::Database.new(CatalystDatabase::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _catalyst_ where _uuid_=?", [uuid]
        db.execute "insert into _catalyst_ (_uuid_, _unixtime_, _description_, _catalystType_, _payload1_, _payload2_, _payload3_) values (?,?,?,?,?,?,?)", [uuid, unixtime, description, catalystType, payload1, payload2, payload3]
        db.commit 
        db.close
    end

    # CatalystDatabase::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(CatalystDatabase::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _catalyst_ where _uuid_=?" , [uuid] ) do |row|
            answer = {
                "uuid"         => row["_uuid_"],
                "unixtime"     => row["_unixtime_"],
                "description"  => row["_description_"],
                "catalystType" => row["_catalystType_"],
                "payload1"     => row["_payload1_"],
                "payload2"     => row["_payload2_"],
                "payload3"     => row["_payload3_"]
            }
        end
        db.close
        answer
    end

    # CatalystDatabase::getObjectsByCatalystType(type)
    def self.getObjectsByCatalystType(type)
        db = SQLite3::Database.new(CatalystDatabase::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _catalyst_ where _catalystType_=? order by _unixtime_" , [type] ) do |row|
            answer << {
                "uuid"         => row["_uuid_"],
                "unixtime"     => row["_unixtime_"],
                "description"  => row["_description_"],
                "catalystType" => row["_catalystType_"],
                "payload1"     => row["_payload1_"],
                "payload2"     => row["_payload2_"],
                "payload3"     => row["_payload3_"]
            }
        end
        db.close
        answer
    end


    # CatalystDatabase::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(CatalystDatabase::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _catalyst_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

end
