
# encoding: UTF-8

class MarbleElizabeth

    # @filepath

    def initialize(filepath)
        @filepath = filepath
    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [nhash]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [nhash, blob]
        db.commit 
        db.close
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)

        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
            blob = row['_value_']
        end
        db.close
        return blob if blob

        # When I did the original data migration, some blobs endded up in Asteroids-TheBigBlobs. Don't ask why...
        # (Actually, they were too big for sqlite, and the existence of those big blogs in the first place is because
        # "ClickableType" data exist in one big blob 🙄)

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles-TheLargeMigrationBlobs/#{nhash}.data"
        if File.exists?(filepath) then
            return IO.read(filepath) 
        end

        raise "[AsteroidElizabeth error: 2400b1c6-42ff-49d0-b37c-fbd37f179e01]"
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class Marble

    # @filepath

    def set(key, value)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [key, value]
        db.commit 
        db.close
    end

    def getOrNull(key)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _data_ where _key_=?", [key]) do |row|
            answer = row['_value_']
        end
        db.close
        answer
    end

    # -----------------------------------------------------

    def intialize(filepath)
        @filepath = filepath

        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117  
            db.busy_handler { |count| true }
            db.execute "create table _data_ (_key_ string, _value_ blob)", []
            db.close
        end
    end

    def uuid()
        getOrNull("uuid")
    end

    def unixtime()
        getOrNull("unixtime")
    end

    def description()
        getOrNull("description")
    end

    def type()
        getOrNull("type")
    end

    def destroy()
        FileUtils.rm(@filepath)
    end
end
