# encoding: UTF-8

class DoNotShowUntil

    # DoNotShowUntil::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::pathToDataBankStargate()}/Catalyst/DoNotShowUntil.sqlite3"
    end

    # DoNotShowUntil::setUnixtime(uid, unixtime)
    def self.setUnixtime(uid, unixtime)
        db = SQLite3::Database.new(DoNotShowUntil::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from table1 where _key_=?", [uid]
        db.execute "insert into table1 (_key_, _value_) values (?,?)", [uid, unixtime]
        db.commit 
        db.close
        SyncEventSpecific::postDoNotShowUntil(uid, unixtime, Machines::theOtherMachine())
        nil
    end

    # DoNotShowUntil::getUnixtimeOrNull(uid)
    def self.getUnixtimeOrNull(uid)
        return nil if !File.exists?(DoNotShowUntil::databaseFilepath()) # happens on Lucille18
        db = SQLite3::Database.new(DoNotShowUntil::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        unixtime = nil
        db.execute( "select * from table1 where _key_=?" , [uid] ) do |row|
            unixtime = row['_value_']
        end
        db.close

        return nil if unixtime.nil?
        unixtime.to_i
    end

    # DoNotShowUntil::getDateTimeOrNull(uid)
    def self.getDateTimeOrNull(uid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uid)
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uid)
    def self.isVisible(uid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
