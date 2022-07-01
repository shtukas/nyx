class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central"
    end
end

class StargateCentralData

    # StargateCentralData::propagateData()
    def self.propagateData()
        Find.find("#{Config::pathToDataBankStargate()}/Data") do |path|
            next if File.directory?(path)
            next if File.basename(path)[0, 1] == "."

            filename = File.basename(path)

            fragment = (lambda {|filename|
                if filename.start_with?("SHA256-") then
                    filename[7, 2] # datablob (.data), aion-points (.data-island.sqlite3)
                else
                    filename[0, 2] # primitive file (.primitive-file-island.sqlite3)
                end
            }).call(filename)

            filepath2 = "#{StargateCentral::pathToCentral()}/Data/#{fragment}/#{filename}"

            if File.exists?(filepath2) then
                next
            end

            if !File.exists?(File.dirname(filepath2)) then
                FileUtils.mkdir(File.dirname(filepath2))
            end

            puts "copying file: #{path}"
            FileUtils.cp(path, filepath2)
        end
    end
end

class StargateCentralObjects

    # StargateCentralObjects::pathToObjectsDatabase()
    def self.pathToObjectsDatabase()
        "#{StargateCentral::pathToCentral()}/objects.sqlite3"
    end

    # StargateCentralObjects::objects()
    def self.objects()
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objects = []
        db.execute("select * from _objects_") do |row|
            object = JSON.parse(row['_object_'])
            if object["variant"].nil? then
                object["variant"] = row['_variant_']
            end
            objects << object
        end
        db.close
        objects
    end

    # StargateCentralObjects::commit(object)
    def self.commit(object)
        raise "(error: ee5c0d42-685e-433a-9d5b-c043494f19ff, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: a98ef432-f4f5-43e2-82ba-2edafa505a8d, missing attribute mikuType)" if object["mikuType"].nil?

        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.execute "delete from _objects_ where _variant_=?", [object["variant"]]
        db.execute "insert into _objects_ (_uuid_, _variant_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["uuid"], object["variant"], object["mikuType"], JSON.generate(object)]
        db.close

        Cliques::garbageCollectCentralCliqueAutomatic(object["uuid"])
    end

    # StargateCentralObjects::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objects = []
        db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
            object = JSON.parse(row['_object_'])
            if object["variant"].nil? then
                object["variant"] = row['_variant_']
            end
            objects << object
        end
        db.close
        objects
    end

    # StargateCentralObjects::getClique(uuid)
    def self.getClique(uuid) 
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objects = []
        db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
            object = JSON.parse(row['_object_'])
            if object["variant"].nil? then
                object["variant"] = row['_variant_']
            end
            objects << object
        end
        db.close
        objects
    end

    # StargateCentralObjects::destroyVariantNoEvent(variant)
    def self.destroyVariantNoEvent(variant)
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.execute "delete from _objects_ where _variant_=?", [variant]
        db.close
    end
end
