# encoding: UTF-8

# create table _mapping_ (_uuid_ text primary key, _unixtime_ float);

class DoNotShowUntil

    # DoNotShowUntil::pathToMapping()
    def self.pathToMapping()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/DoNotShowUntil.sqlite3"
    end

    # DoNotShowUntil::setUnixtimeNoEvents(uuid, unixtime)
    def self.setUnixtimeNoEvents(uuid, unixtime)
        $dnsu_database_semaphore.synchronize { 
            db = SQLite3::Database.new(DoNotShowUntil::pathToMapping())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _mapping_ where _uuid_=?", [uuid]
            db.execute "insert into _mapping_ (_uuid_, _unixtime_) values (?, ?)", [uuid, unixtime]
            db.close
        }
    end

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)

        DoNotShowUntil::setUnixtimeNoEvents(uuid, unixtime)

        event = {
          "uuid"           => SecureRandom.uuid,
          "mikuType"       => "NxDoNotShowUntil",
          "targetuuid"     => uuid,
          "targetunixtime" => unixtime
        }
        SystemEvents::broadcast(event)
    end

    # DoNotShowUntil::processEvent(event)
    def self.processEvent(event)
        return if event["mikuType"] != "NxDoNotShowUntil"
        uuid     = event["targetuuid"]
        unixtime = event["targetunixtime"]
        DoNotShowUntil::setUnixtimeNoEvents(uuid, unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        unixtime = nil
        $dnsu_database_semaphore.synchronize {
            db = SQLite3::Database.new(DoNotShowUntil::pathToMapping())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _mapping_ where _uuid_=?", [uuid]) do |row|
                unixtime = row['_unixtime_']
            end
        }
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
