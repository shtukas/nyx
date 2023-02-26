
class NxNode

    # NxNode.new(filepath)
    def initialize(filepath)
         @filepath = filepath
    end

    # ----------------------------------------------------
    # Generic IO

    def get(key)
        data = nil
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from orbital where _key_=?", [key]) do |row|
            data = row["_data_"]
        end
        db.close
        data
    end

    def set(key, data)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from orbital where _key_=?", [key]
        db.execute "insert into orbital (_key_, _data_) values (?, ?)", [key, data]
        db.close
    end

    def collection(collection) # Array[{key, collection, data}]
        records = []
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from orbital where _collection_=?", [collection]) do |row|
            records << {
                "key"        => row["_key_"],
                "collection" => row["_collection_"],
                "data"       => row["_data_"],
            }
        end
        db.close
        records
    end

    def collection_add(key, collection, data)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from orbital where _key_=?", [key]
        db.execute "insert into orbital (_key_, _collection_, _data_) values (?, ?, ?)", [key, collection, data]
        db.close
    end

    def collection_remove(key)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from orbital where _key_=?", [key]
        db.close
    end

    # ----------------------------------------------------
    # Convenience Getters

    def filepath()
        @filepath
    end

    def uuid()
        self.get("uuid")
    end

    def unixtime()
        self.get("unixtime")
    end

    def description()
        self.get("description")
    end

    def coredataref()
        self.get("coredataref")
    end

    def linkeduuids()
        self.collection("linked").map{|item| item["data"] }
    end

    def linked_nodes()
        self.linkeduuids()
            .map{|linkeduuid| NightSky::getOrNull(linkeduuid) }
            .compact
    end

    def notes()
        self.collection("note")
            .map{|xnote| JSON.parse(xnote["data"]) }
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # ----------------------------------------------------
    # Convenience Setters

    def coredataref_set(coredataref)
        self.set("coredataref", coredataref)
    end

    def linkeduuids_add(linkeduuid)
        return if self.linkeduuids().include?(linkeduuid)
        self.collection_add("linked:#{linkeduuid}", "linked", linkeduuid)
    end

    def linkeduuids_remove(linkeduuid)
        self.collection_remove("linked:#{linkeduuid}")
    end

    def put_blob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        self.set(nhash, blob)
        nhash
    end

    def add_note(note)
        self.collection_add(note["uuid"], "note", JSON.generate(note))
    end

    # ----------------------------------------------------
    # operations

    def move_to_desktop()
        filepath1 = @filepath
        filepath2 = "#{Config::pathToDesktop()}/#{File.basename(filepath1)}"
        FileUtils.mv(filepath1, filepath2)
        @filepath = filepath2
    end

    def fsck()
        puts "(node #{self.uuid()}) fsck..."
        CoreData::fsckRightOrError(self.coredataref(), self)
        CommonUtils::putsOnPreviousLine("(node #{self.uuid()}) ✅")
    end
end

class Elizabeth

    def initialize(node)
        @node = node
    end

    def putBlob(datablob)
        nhash1 = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        nhash2 = @node.put_blob(datablob)

        if nhash2 != nhash1 then
            raise "(error: 88b68200-1a95-4ba3-ad2a-f6ffe6c9fb88) something incredibly wrong just happened"
        end

        nhash3 = "SHA256-#{Digest::SHA256.hexdigest(@node.get(nhash1))}"
        if nhash3 != nhash1 then
            raise "(error: 43070006-dcaf-48b7-ac43-025ed2351336) something incredibly wrong just happened"
        end

        nhash1
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        @node.get(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = self.getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 585b8f91-4369-4dd7-a134-f00d9e7f4391) could not find blob, nhash: #{nhash}"
        raise "(error: 987f8b3e-ff09-4b6a-9809-da6732b39be1, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = self.readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: d97f7216-afeb-40bd-a37c-0d5966e6a0d0) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
