
class DataStore2SQLiteBlobStore

    # DataStore2SQLiteBlobStore::createDatabase(filepath)
    def self.createDatabase(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _dxf4_ (_nhash_ text, _datablob_ blob)", [])
        db.close
    end

    # DataStore2SQLiteBlobStore::putBlob(filepath, datablob)
    def self.putBlob(filepath, datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dxf4_ where _nhash_=?", [nhash]
        db.execute "insert into _dxf4_ (_nhash_, _datablob_) values (?, ?)", [nhash, datablob]
        db.close
    end

    # DataStore2SQLiteBlobStore::getBlobOrNull(filepath, nhash)
    def self.getBlobOrNull(filepath, nhash)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _dxf4_ where _nhash_=?", [nhash]) do |row|
            blob = row["_datablob_"]
        end
        db.close
        blob
    end
end

class DataStore2SQLiteBlobStoreElizabethTheForge

    def initialize()
        @filepath = "/tmp/#{SecureRandom.hex}"
        DataStore2SQLiteBlobStore::createDatabase(@filepath)
    end

    def putBlob(datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        DataStore2SQLiteBlobStore::putBlob(@filepath, datablob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        raise "(error: 08288a21-ad9c-40f9-8dec-9afd99688d4c) nhash: #{nhash}"
    end

    def readBlobErrorIfNotFound(nhash)
        raise "(error: a33d4198-bd2a-4695-bfd0-65c1ab0ef967) nhash: #{nhash}"
    end

    def datablobCheck(nhash)
        raise "(error: 477e4fcc-e32e-4a8e-9221-c50c1a1bad27) nhash: #{nhash}"
    end

    def publish() # nhash
        DataStore1::putDataByFilepath(@filepath) # nhash
    end
end

class DataStore2SQLiteBlobStoreElizabethReadOnly

    def initialize(filepath)
        @filepath = filepath
    end

    def putBlob(datablob)
        raise "(error: 4fbec6b9-4f11-4a6a-b125-f896ace69558)"
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        DataStore2SQLiteBlobStore::getBlobOrNull(@filepath, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 59674f1a-d746-4544-951e-f2b3fa73b121) could not find blob, nhash: #{nhash}"
        raise "(error: 133b9867-5d6d-429c-88c2-e1b87081489b, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: e3981133-9909-4765-9f6b-b76324af0ae8) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end