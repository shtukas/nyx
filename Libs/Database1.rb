
# Database
# create table objects (uuid text, mikuType text, unixtime float, datetime text, description text, doNotShowUntil float, field1 text, field2 text, field3 text, field4 text, field5 text, field6 text, field7 text, field8 text, field9 text);

class Database1

    # Database1::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToDataCenter()}/Database1/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid text, mikuType text, unixtime float, datetime text, description text, doNotShowUntil float, field1 text, field2 text, field3 text, field4 text, field5 text, field6 text, field7 text, field8 text, field9 text);", [])
        db.close
        filepath
    end

    # Database1::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)

    end

    # Database1::commit(object)
    def self.commit(object)

    end

    # Database1::updateAttribute(uuid, name, value)
    def self.updateAttribute(uuid, name, value)

    end

    # Database1::query(query, parameters)
    def self.query(query, parameters)

    end

end