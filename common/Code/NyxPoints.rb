# encoding: UTF-8

require 'sqlite3'

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class NyxPointsElizabeth

    # @filepath

    def initialize(filepath)
        @filepath = filepath
    end

    def commitBlob(blob)
        NyxPoints::commitBlob(@filepath, blob)
    end

    def getBlobOrNull(nhash)
        NyxPoints::getBlobOrNull(@filepath, nhash)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        NyxPoints::readBlobErrorIfNotFound(@filepath, nhash)
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

class NyxPoints

    # NyxPoints::issueNewEmptyMarbleFile(filepath)
    def self.issueNewEmptyMarbleFile(filepath)
        raise "[5f930502-bb08-4971-8323-27c0c0031477: #{filepath}]" if File.exists?(filepath)

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "create table _data_ (_key_ string, _value_ blob)", []
        db.execute "create table _filetype_ (_id_ string)", []
        db.execute "insert into _filetype_ (_id_) values (?)", ["001-8b0aac1fcea0"]

        db.close
        nil
    end

    # NyxPoints::keys(filepath)
    def self.keys(filepath)
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "ce1a703e-1104-44a6-b9ea-cc1c2f82bd8d" if !File.exists?(filepath)
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

    # NyxPoints::version(filepath)
    def self.version(filepath)
        raise "74fbcdd4-9301-4041-bafe-d61e2818c2f2" if !File.exists?(filepath)
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

    # NyxPoints::kvstore_set(filepath, key, value)
    def self.kvstore_set(filepath, key, value)
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "08bf2e43-d8cf-4873-b8e2-82f5c1e7fa2a" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [key, value]
        db.commit 
        db.close
    end

    # NyxPoints::kvstore_getOrNull(filepath, key)
    def self.kvstore_getOrNull(filepath, key) # binary data or null
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "ce1a703e-1104-44a6-b9ea-cc1c2f82bd8d" if !File.exists?(filepath)
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

    # NyxPoints::kvstore_get(filepath, key)
    def self.kvstore_get(filepath, key)
        data = NyxPoints::kvstore_getOrNull(filepath, key)
        raise "error: 80412ec7-7cb4-4e93-bb3f-e9bb81b22f8e: could not extract mandatory key '#{key}' at filepath '#{filepath}'" if data.nil?
        data
    end

    # NyxPoints::kvstore_destroy(filepath, key)
    def self.kvstore_destroy(filepath, key)
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "80a79666-bc77-4347-a114-93a87738ced0" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.commit 
        db.close
    end

    # -- sets  --------------------------------------------------

    # NyxPoints::sets_add(filepath, setId, dataId, data)
    def self.sets_add(filepath, setId, dataId, data)
        raise "87462e7a-80f0-4a4b-8723-4d66a71ba88b" if !File.exists?(filepath)
        NyxPoints::kvstore_set(filepath, "#{setId}:#{dataId}", data)
    end

    # NyxPoints::sets_remove(filepath, setId, dataId)
    def self.sets_remove(filepath, setId, dataId)
        raise "934b097e-4cfc-40ba-b48d-93f5f04cf4f4" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        NyxPoints::kvstore_destroy(filepath, "#{setId}:#{dataId}")
    end

    # NyxPoints::sets_getElementByIdOrNull(filepath, setId, dataId)
    def self.sets_getElementByIdOrNull(filepath, setId, dataId)
        raise "8975c020-9645-4597-8e22-7d40572412b6: #{filepath}" if !File.exists?(filepath)
        NyxPoints::kvstore_getOrNull(filepath, "#{setId}:#{dataId}")
    end

    # NyxPoints::sets_getElements(filepath, setId)
    def self.sets_getElements(filepath, setId)
        raise "d0281dea-0fd8-4ead-88cf-ea591950ecdc: #{filepath}" if !File.exists?(filepath)
        NyxPoints::keys(filepath)
            .select{|key| key.start_with?("#{setId}:") }
            .map{|key| NyxPoints::kvstore_get(filepath, key) } # We could also use NyxPoints::kvstore_getOrNull
    end

    # -- data blobs store --------------------------------------------------

    # NyxPoints::commitBlob(filepath, blob)
    def self.commitBlob(filepath, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        NyxPoints::kvstore_set(filepath, nhash, blob)
        nhash
    end

    # NyxPoints::getBlobOrNull(filepath, nhash)
    def self.getBlobOrNull(filepath, nhash)
        NyxPoints::kvstore_getOrNull(filepath, nhash)
    end

    # NyxPoints::readBlobErrorIfNotFound(filepath, nhash)
    def self.readBlobErrorIfNotFound(filepath, nhash)
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        blob = NyxPoints::kvstore_getOrNull(filepath, nhash)
        return blob if blob
        raise "[Error: 3CCC5678-E1FE-4729-B72B-C7E5D7951983, nhash: #{nhash}]"
    end

    # -- tests --------------------------------------------------

    # NyxPoints::selfTest()
    def self.selfTest()
        filepath = "/tmp/#{SecureRandom.hex}"
        NyxPoints::issueNewEmptyMarbleFile(filepath)

        raise "1d464a8d-d4ed-4d81-8e02-1ebeae50df30" if !File.exists?(filepath)

        raise "233d0296-c776-4ed8-a656-5ce7810f901c" if NyxPoints::version(filepath) != "001-8b0aac1fcea0"

        NyxPoints::kvstore_set(filepath, "key1", "value1")

        raise "8316ff18-00b9-4bb3-b1e1-93fec175feee" if (NyxPoints::kvstore_getOrNull(filepath, "key1") != "value1")
        raise "38965323-6b0e-4581-ba9b-af75df8137ef" if (NyxPoints::kvstore_get(filepath, "key1") != "value1")

        begin
            NyxPoints::kvstore_get(filepath, "key2") 
            puts "You should not read this"
        rescue
        end

        NyxPoints::sets_add(filepath, "set1", "1", "Alice")
        NyxPoints::sets_add(filepath, "set1", "1", "Beth")
        NyxPoints::sets_add(filepath, "set1", "2", "Celia")

        raise "c3c17399-e6ec-4792-985f-871517f4afc1" if (NyxPoints::sets_getElementByIdOrNull(filepath, "set1", "2") != "Celia")

        set = NyxPoints::sets_getElements(filepath, "set1")

        raise "258752df-0fa0-412a-999e-9ed50f1f66c0" if (set.sort.join(":") != "Beth:Celia")

        FileUtils.rm(filepath)
        puts "NyxPoints::selfTest(), all good!"
    end
end
