
# create table datablock (uuid TEXT, nhash TEXT, datablob BLOB);
# CREATE INDEX index1 ON datablock(uuid, nhash);

class Datablocks

    # Datablocks::directory()
    def self.directory()
        "#{Config::pathToData()}/Datablocks"
    end

    # Datablocks::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Datablocks::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .sort
    end

    # Datablocks::filepathForInsertion()
    def self.filepathForInsertion()
        filepaths = Datablocks::filepaths().select{|filepath|
            sizeInMegabytes = File.size(filepath).to_f/(1024*1024)
            sizeInMegabytes < 500
        }
        if filepaths.empty? then
            # We need to initiate a database
            filepath = "#{Datablocks::directory()}/#{SecureRandom.hex}.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.transaction
            db.execute("create table datablock (uuid TEXT, nhash TEXT, datablob BLOB);", [])
            db.execute("CREATE INDEX index1 ON datablock(uuid, nhash);", [])
            db.commit
            db.close
            return filepath
        else
            return filepaths.sort_by{|filepath| File.size(filepath) }.first
        end
    end

    # Datablocks::hasEntryAtFile(filepath, uuid, nhash)
    def self.hasEntryAtFile(filepath, uuid, nhash)
        answer = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablock where uuid=? and nhash=?", [uuid, nhash]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # Datablocks::hasEntryAtRepository(uuid, nhash)
    def self.hasEntryAtRepository(uuid, nhash)
        Datablocks::filepaths().each{|filepath|
            return true if Datablocks::hasEntryAtFile(filepath, uuid, nhash)
        }
        false
    end

    # Datablocks::ensureContentAddressing(filepath1)
    def self.ensureContentAddressing(filepath1)
        hash1 = Digest::SHA1.file(filepath1).hexdigest
        filepath2 = "#{Datablocks::directory()}/#{hash1}.sqlite3"
        return filepath1 if filepath1 == filepath2
        FileUtils.mv(filepath1, filepath2)
        filepath2
    end

    # Datablocks::getDatablobOrNullAtFile(filepath, uuid, nhash)
    def self.getDatablobOrNullAtFile(filepath, uuid, nhash)
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablock where uuid=? and nhash=?", [uuid, nhash]) do |row|
            datablob = row["datablob"]
        end
        db.close
        datablob
    end

    # Datablocks::removeUUIDAtFile(filepath, uuid)
    def self.removeUUIDAtFile(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from datablock where uuid=?", [uuid])
        db.close
        Datablocks::ensureContentAddressing(filepath)
    end

    # -----------------------------------------------------
    # Interface

    # Datablocks::putDatablob(uuid, datablob) -> nhash
    def self.putDatablob(uuid, datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        return nhash if Datablocks::hasEntryAtRepository(uuid, nhash)

        filepath = Datablocks::filepathForInsertion()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("insert into datablock (uuid, nhash, datablob) values (?, ?, ?)", [uuid, nhash, datablob])
        db.commit
        db.close

        Datablocks::ensureContentAddressing(filepath)

        # Let's do a read for conformation
        datablob2 = Datablocks::getDatablobOrNull(uuid, nhash)
        if datablob != datablob2 then
            puts "(error: c2ca6fa6) could not read datablobd #{nhash} after writing it"
            raise "(error: 533d1421)"
        end

        nhash
    end

    # Datablocks::getDatablobOrNull(uuid, nhash)
    def self.getDatablobOrNull(uuid, nhash)
        Datablocks::filepaths().each{|filepath|
            datablob = Datablocks::getDatablobOrNullAtFile(filepath, uuid, nhash)
            if datablob then
                nhash2 = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
                if nhash != nhash2 then
                    puts "(error: 03220859) could not retrieve nhash: #{nhash}, the read datablob does not check out"
                    raise "(error: 435657ab)"
                end
                return datablob
            end
        }
        nil
    end

    # Datablocks::removeUUID(uuid)
    def self.removeUUID(uuid)
        Datablocks::filepaths().each{|filepath|
            Datablocks::removeUUIDAtFile(filepath, uuid)
        }
    end
end
