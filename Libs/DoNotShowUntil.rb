# encoding: UTF-8

# create table _dnsu_ (_uuid_ text, _unixtime_ float);

class DoNotShowUntil

    # DoNotShowUntil::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Databases/do-not-show-until.sqlite3"
    end

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        db = SQLite3::Database.new(DoNotShowUntil::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dnsu_ where _uuid_=?", [uuid]
        db.execute "insert into _dnsu_ (_uuid_, _unixtime_) values (?, ?)", [uuid, unixtime]
        db.close
        SystemEvents::broadcast({
            "mikuType"       => "NxDoNotShowUntil",
            "targetuuid"     => uuid,
            "targetunixtime" => unixtime
        })
    end

    # DoNotShowUntil::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "NxDoNotShowUntil" then
            FileSystemCheck::fsckNxDoNotShowUntil(event, SecureRandom.hex, false)
            uuid     = event["targetuuid"]
            unixtime = event["targetunixtime"]
            db = SQLite3::Database.new(DoNotShowUntil::pathToDatabase())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from _dnsu_ where _uuid_=?", [uuid]
            db.execute "insert into _dnsu_ (_uuid_, _unixtime_) values (?, ?)", [uuid, unixtime]
            db.close
        end
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        db = SQLite3::Database.new(DoNotShowUntil::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        unixtime = nil
        db.execute("select * from _dnsu_ where _uuid_=?", [uuid]) do |row|
            unixtime = row["_unixtime_"]
        end
        db.close
        unixtime
    end

    # DoNotShowUntil::getDateTimeOrNull(uuid)
    def self.getDateTimeOrNull(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
