# encoding: UTF-8

require 'sqlite3'

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class Fx12sElizabeth

    # @filepath

    def initialize(filepath)
        @filepath = filepath
    end

    def commitBlob(blob)
        Fx12s::commitBlob(@filepath, blob)
    end

    def getBlobOrNull(nhash)
        Fx12s::getBlobOrNull(@filepath, nhash)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        Fx12s::readBlobErrorIfNotFound(@filepath, nhash)
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

class Fx12sElizabethV2

    def initialize(uuid)
        @filepath = Librarian::getFx12Filepath(uuid)
    end

    def commitBlob(blob)
        Fx12s::commitBlob(@filepath, blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Fx12s::getBlobOrNull(@filepath, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 7ffc6f95-4977-47a2-b9fd-eecd8312ebbe) could not find blob, nhash: #{nhash}"
        raise "(error: 47f74e9a-0255-44e6-bf04-f12ff7786c65, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 479c057e-d77b-4cd9-a6ba-df082e93f6b5) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class Fx12s

    # Fx12s::issueNewEmptyMarbleFile(filepath)
    def self.issueNewEmptyMarbleFile(filepath)
        raise "[f2a0afca-e1cc-4f76-a509-d1725e8e0432: #{filepath}]" if File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "create table _data_ (_key_ string, _value_ blob)", []
        db.execute "create table _filetype_ (_id_ string)", []
        db.execute "insert into _filetype_ (_id_) values (?)", ["001-8b0aac1fcea0"]
        db.close
        nil
    end

    # Fx12s::createFileIfNotCreatedYet(filepath)
    def self.createFileIfNotCreatedYet(filepath)
        return if File.exists?(filepath)
        Fx12s::issueNewEmptyMarbleFile(filepath)
    end

    # Fx12s::keys(filepath)
    def self.keys(filepath)
        Fx12s::createFileIfNotCreatedYet(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        keys = []
        db.execute("select _key_ from _data_", []) do |row|
            keys << row['_key_']
        end
        db.close
        keys
    end

    # Fx12s::version(filepath)
    def self.version(filepath)
        Fx12s::createFileIfNotCreatedYet(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        value = nil
        db.execute("select _id_ from _filetype_", []) do |row|
            value = row['_id_']
        end
        db.close
        value
    end

    # -- key-value store --------------------------------------------------

    # Fx12s::kvstore_set(filepath, key, value)
    def self.kvstore_set(filepath, key, value)
        Fx12s::createFileIfNotCreatedYet(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [key, value]
        db.commit 
        db.close
    end

    # Fx12s::kvstore_getOrNull(filepath, key)
    def self.kvstore_getOrNull(filepath, key) # binary data or null
        Fx12s::createFileIfNotCreatedYet(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        value = nil
        db.execute("select * from _data_ where _key_=?", [key]) do |row|
            value = row['_value_']
        end
        db.close
        value
    end

    # Fx12s::kvstore_get(filepath, key)
    def self.kvstore_get(filepath, key)
        data = Fx12s::kvstore_getOrNull(filepath, key)
        raise "error: 80412ec7-7cb4-4e93-bb3f-e9bb81b22f8e: could not extract mandatory key '#{key}' at filepath '#{filepath}'" if data.nil?
        data
    end

    # Fx12s::kvstore_destroy(filepath, key)
    def self.kvstore_destroy(filepath, key)
        Fx12s::createFileIfNotCreatedYet(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.commit 
        db.close
    end

    # -- sets  --------------------------------------------------

    # Fx12s::sets_add(filepath, setId, dataId, data)
    def self.sets_add(filepath, setId, dataId, data)
        Fx12s::kvstore_set(filepath, "#{setId}:#{dataId}", data)
    end

    # Fx12s::sets_remove(filepath, setId, dataId)
    def self.sets_remove(filepath, setId, dataId)
        Fx12s::kvstore_destroy(filepath, "#{setId}:#{dataId}")
    end

    # Fx12s::sets_getElementByIdOrNull(filepath, setId, dataId)
    def self.sets_getElementByIdOrNull(filepath, setId, dataId)
        Fx12s::kvstore_getOrNull(filepath, "#{setId}:#{dataId}")
    end

    # Fx12s::sets_getElements(filepath, setId)
    def self.sets_getElements(filepath, setId)
        Fx12s::keys(filepath)
            .select{|key| key.start_with?("#{setId}:") }
            .map{|key| Fx12s::kvstore_get(filepath, key) } # We could also use Fx12s::kvstore_getOrNull
    end

    # -- data blobs store --------------------------------------------------

    # Fx12s::commitBlob(filepath, blob)
    def self.commitBlob(filepath, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Fx12s::kvstore_set(filepath, nhash, blob)
        nhash
    end

    # Fx12s::getBlobOrNull(filepath, nhash)
    def self.getBlobOrNull(filepath, nhash)
        Fx12s::kvstore_getOrNull(filepath, nhash)
    end

    # Fx12s::readBlobErrorIfNotFound(filepath, nhash)
    def self.readBlobErrorIfNotFound(filepath, nhash)
        blob = Fx12s::kvstore_getOrNull(filepath, nhash)
        return blob if blob
        raise "[Error: 3CCC5678-E1FE-4729-B72B-C7E5D7951983, nhash: #{nhash}]"
    end

    # -- tests --------------------------------------------------

    # Fx12s::selfTest()
    def self.selfTest()
        filepath = "/tmp/#{SecureRandom.hex}"
        Fx12s::issueNewEmptyMarbleFile(filepath)

        raise "1d464a8d-d4ed-4d81-8e02-1ebeae50df30" if !File.exists?(filepath)

        raise "233d0296-c776-4ed8-a656-5ce7810f901c" if Fx12s::version(filepath) != "001-8b0aac1fcea0"

        Fx12s::kvstore_set(filepath, "key1", "value1")

        raise "8316ff18-00b9-4bb3-b1e1-93fec175feee" if (Fx12s::kvstore_getOrNull(filepath, "key1") != "value1")
        raise "38965323-6b0e-4581-ba9b-af75df8137ef" if (Fx12s::kvstore_get(filepath, "key1") != "value1")

        begin
            Fx12s::kvstore_get(filepath, "key2") 
            puts "You should not read this"
        rescue
        end

        Fx12s::sets_add(filepath, "set1", "1", "Alice")
        Fx12s::sets_add(filepath, "set1", "1", "Beth")
        Fx12s::sets_add(filepath, "set1", "2", "Celia")

        raise "c3c17399-e6ec-4792-985f-871517f4afc1" if (Fx12s::sets_getElementByIdOrNull(filepath, "set1", "2") != "Celia")

        set = Fx12s::sets_getElements(filepath, "set1")

        raise "258752df-0fa0-412a-999e-9ed50f1f66c0" if (set.sort.join(":") != "Beth:Celia")

        FileUtils.rm(filepath)
        puts "Fx12s::selfTest(), all good!"
    end
end
