
# encoding: UTF-8

class Tags

    # Tags::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/tags.sqlite3"
    end

    # Tags::insert(unixtime, owneruuid, payload)
    def self.insert(unixtime, owneruuid, payload)
        uuid = SecureRandom.uuid
        db = SQLite3::Database.new(Tags::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _tags_ (_uuid_, _unixtime_, _owneruuid_, _payload_) values (?, ?, ?, ?)", [uuid, unixtime, owneruuid, payload]
        db.close
    end

    # Tags::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(Tags::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _tags_ where _uuid_=?", [uuid]
        db.close
    end

    # Tags::tags()
    def self.tags()
        db = SQLite3::Database.new(Tags::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _tags_" , [] ) do |row|
            answer << {
                "uuid"      => row["_uuid_"],
                "unixtime"  => row["_unixtime_"],
                "owneruuid" => row["_owneruuid_"],
                "payload"   => row["_payload_"],
            }
        end
        db.close
        answer
    end

    # Tags::tagsForOwner(owneruuid)
    def self.tagsForOwner(owneruuid)
        Tags::tags()
            .select{|tag| tag["owneruuid"] == owneruuid }
    end

    # Tags::toString(tag)
    def self.toString(tag)
        "[tag] #{tag["payload"]}"
    end
end
