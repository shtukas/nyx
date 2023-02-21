
class NxOrbital

    # NxOrbital.new(filepath)
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

    def toString()
        "#{self.get("description")}"
    end

    def coredataref()
        self.get("coredataref")
    end

    def linkeduuids()
        collection("linked").map{|item| item["data"] }
    end

    def linked_orbitals()
        linkeduuids().map{|linkeduuid| NightSky::getOrNull(linkeduuid) }
    end

    def companion_directory_or_null()
        components = NightSky::filenameComponentsOrNull(File.basename(@filepath))
        if components.nil? then
            raise "(error: 41365d27-718a-4f56-8748-df61a15933d6) this should not have happened: #{@filepath}"
        end
        directory = "#{File.dirname(@filepath)}/#{components["main"]}"
        return nil if !File.exist?(directory)
        directory
    end

    # ----------------------------------------------------
    # Convenience Setters

    def coredataref_set(coredataref)
        self.set("coredataref", coredataref)
    end

    def linkeduuids_add(linkeduuid)
        return if self.linkeduuids().include?(linkeduuid)
        collection_add("linked:#{linkeduuid}", "linked", linkeduuid)
    end

    def linkeduuids_remove(linkeduuid)
        collection_remove("linked:#{linkeduuid}")
    end

    # ----------------------------------------------------
    # operations

    def move_to_desktop()
        if companion_directory_or_null() then
            puts "We have a companion directory"
            puts "I am moving you there"
            LucilleCore::pressEnterToContinue()
            system("open '#{companion_directory_or_null()}'")
            LucilleCore::pressEnterToContinue()
            return
        end

        filepath1 = @filepath
        filepath2 = "#{Config::pathToDesktop()}/#{File.basename(filepath1)}"
        FileUtils.mv(filepath1, filepath2)
        @filepath = filepath2
    end
end
