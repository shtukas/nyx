# encoding: UTF-8

class Omegas

    # Omegas::initiate(filepath, uuid)
    def self.initiate(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("CREATE TABLE datablobs (key string, datablob blob);", [])
        db.commit
        db.close
    end

    # Omegas::putBlob2(bladefilepath, datablob)
    def self.putBlob2(bladefilepath, datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        db = SQLite3::Database.new(bladefilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from datablobs where key=?", [nhash])
        db.execute("insert into datablobs (key, datablob) values (?, ?)", [nhash, datablob])
        db.commit
        db.close
        nhash
    end

    # Omegas::getBlob2(bladefilepath, nhash)
    def self.getBlob2(bladefilepath, nhash)
        datablob = nil
        db = SQLite3::Database.new(bladefilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablobs where key=?", [nhash]) do |row|
            datablob = row["datablob"]
        end
        db.close
        datablob
    end
end

class ElizabethBlade

    def initialize(bladefilepath)
        @bladefilepath = bladefilepath
    end

    def putBlob(datablob) # nhash
        Omegas::putBlob2(@bladefilepath, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        datablob = Omegas::getBlob2(@bladefilepath, nhash)
        if datablob and (nhash != "SHA256-#{Digest::SHA256.hexdigest(datablob)}") then
            datablob = nil
        end
        datablob
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: ff339aa3-b7ea-4b92-a211-5fc1048c048b, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 900a9a53-66a3-4860-be5e-dffa7a88c66d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
