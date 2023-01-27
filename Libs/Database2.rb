# encoding: UTF-8

class Database2Adaptation

    # Database2Adaptation::databaseObjectToItem(object)
    def self.databaseObjectToItem(object)
        if object["mikuType"] == "NxTodo" then
            object["nx113"] = JSON.parse(object["field1"])
            object["tcId"]  = object["field2"]
            object["tcPos"] = object["field3"]
            return object
        end
        if object["mikuType"] == "NxAnniversary" then
            object["startdate"]           = object["field1"]
            object["repeatType"]          = object["field2"]
            object["lastCelebrationDate"] = object["field3"]
            return object
        end
        raise "(error: 002d8744-e34d-4307-b573-73a195a9c7ac)"
    end

    # Database2Adaptation::itemToDatabaseObject(item)
    def self.itemToDatabaseObject(item)
        if item["mikuType"] == "NxTodo" then
            item["field1"] = JSON.generate(item["nx113"])
            item["field2"] = item["tcId"]
            item["field3"] = item["tcPos"]
            return item
        end
        if item["mikuType"] == "NxAnniversary" then
            item["field1"] = item["startdate"]
            item["field2"] = item["repeatType"]
            item["field3"] = item["lastCelebrationDate"]
            return item
        end
        raise "(error: 34432491-c0a8-45a2-a93c-8a7b132d027e)"
    end

end

class Database2

    # ----------------------------------
    # Interface

    # Database2::itemsForMikuType(mikuType)
    def self.itemsForMikuType(mikuType)
        Database2::database_objects()
            .select{|object| object["mikuType"] == mikuType }
            .map{|object| Database2Adaptation::databaseObjectToItem(object) }
    end

    # Database2::commit_item(item)
    def self.commit_item(item)
        database_object = Database2Adaptation::itemToDatabaseObject(item)
        Database2::commit_object(database_object)
    end

    # Database2::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        object = nil
        Database2::filepaths().each{|filepath|
            object = Database2::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
            break if !object.nil?
        }
        object
    end

    # Database2::destroy(uuid)
    def self.destroy(uuid)
        Database2::filepaths().each{|filepath|
            Database2::deleteObjectInFile(filepath, uuid)
        }
    end

    # ----------------------------------
    # Private

    # Database2::database_objects()
    def self.database_objects()
        objects = {}
        Database2::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from objects", []) do |row|
                objects[row["uuid"]] = Database2::rowToObject(row)
            end
            db.close
        }
        # Note that we used a hash instead of an array because we could easily have the same object appearing several times
        # It's one of the ways the multi instance distributed database can misbehave
        objects.values
    end

    # Database2::commit_object(object)
    def self.commit_object(object)
        # If we want to commit an object, we need to rewrite all the files in which it is (meaning deleting the object and renaming the file)
        # and put it into a new file.

        filepaths = Database2::filepaths()

        filepath0 = Database2::spawnNewDatabase()

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, payload, doNotShowUntil, field1, field2, field3, field4, field5, field6, field7, field8) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], object["unixtime"], object["datetime"], object["description"], object["payload"], object["doNotShowUntil"], object["field1"], object["field2"], object["field3"], object["field4"], object["field5"], object["field6"], object["field7"], object["field8"]]
        db.close

        # Note that we made filepaths, before creating filepath0, so we are not going to delete the object that is being saved from the fie that was just created  
        filepaths.each{|filepath|
            Database2::deleteObjectInFile(filepath, object["uuid"])
        }

        while Database2::filepaths().size > Database2::cardinality() do
            filepath1, filepath2 = Database2::filepaths()
            Database2::mergeFiles(filepath1, filepath2)
        end
    end

    # Database2::cardinality()
    def self.cardinality()
        200
    end

    # Database2::foldername()
    def self.foldername()
        "Database2"
    end

    # Database2::rowToObject(row)
    def self.rowToObject(row)
        {
            "uuid"           => row["uuid"],
            "mikuType"       => row["mikuType"],
            "unixtime"       => row["unixtime"],
            "datetime"       => row["datetime"],
            "description"    => row["description"],
            "payload"        => row["payload"],
            "doNotShowUntil" => row["doNotShowUntil"],
            "field1"         => row["field1"],
            "field2"         => row["field2"],
            "field3"         => row["field3"],
            "field4"         => row["field4"],
            "field5"         => row["field5"],
            "field6"         => row["field6"],
            "field7"         => row["field7"],
            "field8"         => row["field8"],
        }
    end

    # Database2::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToDataCenter()}/#{Database2::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid text primary key, mikuType text, unixtime float, datetime text, description text, payload text, doNotShowUntil float, field1 text, field2 text, field3 text, field4 text, field5 text, field6 text, field7 text, field8 text)", [])
        db.close
        filepath
    end

    # Database2::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{Database2::foldername()}")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # Database2::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
    def self.getObjectFromFilepathByUUIDOrNull(filepath, uuid)
        object = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where uuid=?", [uuid]) do |row|
            object = Database2::rowToObject(row)
        end
        db.close
        object
    end

    # Database2::fileHasObject(filepath, uuid)
    def self.fileHasObject(filepath, uuid)
        !Database2::getObjectFromFilepathByUUIDOrNull(filepath, uuid).nil?
    end

    # Database2::fileIsEmpty(filepath)
    def self.fileIsEmpty(filepath)
        count = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from objects", []) do |row|
            count = row["_count_"]
        end
        db.close
        count == 0
    end

    # Database2::deleteObjectInFile(filepath, uuid)
    def self.deleteObjectInFile(filepath, uuid)
        if !Database2::fileHasObject(filepath, uuid) then
            if Database2::fileIsEmpty(filepath) then
                FileUtils.rm(filepath)
            end
            return
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from objects where uuid=?", [uuid]
        db.close
        if Database2::fileIsEmpty(filepath) then
            FileUtils.rm(filepath)
        else
            # Now we need to rename the file since it's contents have changed
            filepath2 = "#{Config::pathToDataCenter()}/#{Database2::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
            FileUtils.mv(filepath, filepath2)
        end
        nil
    end

    # Database2::mergeFiles(filepath1, filepath2)
    def self.mergeFiles(filepath1, filepath2)
        db1 = SQLite3::Database.new(filepath1)
        db2 = SQLite3::Database.new(filepath2)

        # We move all the objects from db1 to db2

        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        db1.execute("select * from objects", []) do |row|
            db2.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, payload, doNotShowUntil, field1, field2, field3, field4, field5, field6, field7, field8) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [row["uuid"], row["mikuType"], row["unixtime"], row["datetime"], row["description"], row["payload"], row["doNotShowUntil"], row["field1"], row["field2"], row["field3"], row["field4"], row["field5"], row["field6"], row["field7"], row["field8"]]
        end

        db1.close
        db2.close

        # Let's now delete the first file 
        FileUtils.rm(filepath1)


        # And rename the second one
        filepath3 = "#{Config::pathToDataCenter()}/#{Database2::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
        FileUtils.mv(filepath2, filepath3)
    end

end
