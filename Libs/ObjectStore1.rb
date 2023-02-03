# encoding: UTF-8

class ObjectStore1

    # ----------------------------------
    # Config

    # ObjectStore1::cardinality()
    def self.cardinality()
        200
    end

    # ObjectStore1::foldername()
    def self.foldername()
        "ObjectStore1"
    end

    # ----------------------------------
    # Interface

    # ObjectStore1::databaseQuery(querystring, bindings)
    def self.databaseQuery(querystring, bindings)
        objects = {}
        ObjectStore1::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute(querystring, bindings) do |row|
                objects[row["uuid"]] = ObjectStore1::rowToObject(row)
            end
            db.close
        }
        # Note that we used a hash instead of an array because we could easily have the same object appearing several times
        # It's one of the ways the multi instance distributed database can misbehave
        objects.values
    end

    # ObjectStore1::commitItem(item)
    def self.commitItem(item)
        puts "ObjectStore1::commitItem(#{JSON.pretty_generate(item)})"
        FileSystemCheck::fsck_MikuTypedItem(item, true)
        database_object = ObjectStore1ItemObjectsTranslation::itemToDatabaseObject(item)
        ObjectStore1::commitObject(database_object)
    end

    # ObjectStore1::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        item = nil
        ObjectStore1::filepaths().each{|filepath|
            object = ObjectStore1::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
            next if object.nil?
            item = ObjectStore1ItemObjectsTranslation::databaseObjectToItem(object)
            break if !item.nil?
        }
        item
    end

    # ObjectStore1::set(uuid, attname, attvalue)
    def self.set(uuid, attname, attvalue)
        puts "ObjectStore1::set(#{uuid}, #{attname}, #{attvalue})"
        ObjectStore1::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "update objects set #{attname}=? where uuid=?", [attvalue, uuid]
            db.close
        }
    end

    # ObjectStore1::getOrNull(uuid, attname)
    def self.getOrNull(uuid, attname)
        answer = nil
        ObjectStore1::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from objects where uuid=?", [uuid]) do |row|
                answer = row[attname]
            end
            db.close
            if answer then
                return answer
            end
        }
        nil
    end

    # ObjectStore1::destroy(uuid)
    def self.destroy(uuid)
        puts "ObjectStore1::destroy(#{uuid})"
        ObjectStore1::filepaths().each{|filepath|
            ObjectStore1::deleteObjectInFile(filepath, uuid)
        }
    end

    # ----------------------------------
    # Private

    # ObjectStore1::databaseItems()
    def self.databaseItems()
        ObjectStore1::databaseQuery("select * from objects", [])
            .map{|object| ObjectStore1ItemObjectsTranslation::databaseObjectToItem(object) }
    end

    # *Database Schema*
    # ObjectStore1::commitObject(object)
    def self.commitObject(object)
        # If we want to commit an object, we need to rewrite all the files in which it is (meaning deleting the object and renaming the file)
        # and put it into a new file.

        filepaths = ObjectStore1::filepaths()

        filepath0 = ObjectStore1::spawnNewDatabase()

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, payload, doNotShowUntil, field1, field2, field3, field4, field5, field6, field7, field8, field9, field10, field11, field12, field13) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], object["unixtime"], object["datetime"], object["description"], object["payload"], object["doNotShowUntil"], object["field1"], object["field2"], object["field3"], object["field4"], object["field5"], object["field6"], object["field7"], object["field8"], object["field9"], object["field10"], object["field11"], object["field12"], object["field13"]]
        db.close

        # Note that we made filepaths, before creating filepath0, so we are not going to delete the object that is being saved from the fie that was just created  
        filepaths.each{|filepath|
            ObjectStore1::deleteObjectInFile(filepath, object["uuid"])
        }

        while ObjectStore1::filepaths().size > ObjectStore1::cardinality() do
            filepath1, filepath2 = ObjectStore1::filepaths()
            ObjectStore1::mergeFiles(filepath1, filepath2)
        end
    end

    # *Database Schema*
    # ObjectStore1::rowToObject(row)
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
            "field9"         => row["field9"],
            "field10"        => row["field10"],
            "field11"        => row["field11"],
            "field12"        => row["field12"],
            "field13"        => row["field13"],
        }
    end

    # *Database Schema*
    # ObjectStore1::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToDataCenter()}/#{ObjectStore1::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid text primary key, mikuType text, unixtime float, datetime text, description text, payload text, doNotShowUntil float, field1 text, field2 text, field3 text, field4 text, field5 text, field6 text, field7 text, field8 text, field9 text, field10 text, field11 text, field12 text, field13 float)", [])
        db.close
        filepath
    end

    # ObjectStore1::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{ObjectStore1::foldername()}")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # ObjectStore1::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
    def self.getObjectFromFilepathByUUIDOrNull(filepath, uuid)
        object = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where uuid=?", [uuid]) do |row|
            object = ObjectStore1::rowToObject(row)
        end
        db.close
        object
    end

    # ObjectStore1::fileHasObject(filepath, uuid)
    def self.fileHasObject(filepath, uuid)
        !ObjectStore1::getObjectFromFilepathByUUIDOrNull(filepath, uuid).nil?
    end

    # ObjectStore1::fileIsEmpty(filepath)
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

    # ObjectStore1::deleteObjectInFile(filepath, uuid)
    def self.deleteObjectInFile(filepath, uuid)
        if !ObjectStore1::fileHasObject(filepath, uuid) then
            if ObjectStore1::fileIsEmpty(filepath) then
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
        if ObjectStore1::fileIsEmpty(filepath) then
            FileUtils.rm(filepath)
        else
            # Now we need to rename the file since it's contents have changed
            filepath2 = "#{Config::pathToDataCenter()}/#{ObjectStore1::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
            FileUtils.mv(filepath, filepath2)
        end
        nil
    end

    # *Database Schema*
    # ObjectStore1::mergeFiles(filepath1, filepath2)
    def self.mergeFiles(filepath1, filepath2)
        db1 = SQLite3::Database.new(filepath1)
        db2 = SQLite3::Database.new(filepath2)

        # We move all the objects from db1 to db2

        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        db1.execute("select * from objects", []) do |row|
            db2.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, payload, doNotShowUntil, field1, field2, field3, field4, field5, field6, field7, field8, field9, field10, field11, field12, field13) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [row["uuid"], row["mikuType"], row["unixtime"], row["datetime"], row["description"], row["payload"], row["doNotShowUntil"], row["field1"], row["field2"], row["field3"], row["field4"], row["field5"], row["field6"], row["field7"], row["field8"], row["field9"], row["field10"], row["field11"], row["field12"], row["field13"]]
        end

        db1.close
        db2.close

        # Let's now delete the first file 
        FileUtils.rm(filepath1)


        # And rename the second one
        filepath3 = "#{Config::pathToDataCenter()}/#{ObjectStore1::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
        FileUtils.mv(filepath2, filepath3)
    end
end

class ObjectStore1ItemObjectsTranslation

    # ObjectStore1ItemObjectsTranslation::databaseObjectToItem(object)
    def self.databaseObjectToItem(object)

        # ------------------------------------
        # field9, NxBalls

        if object["field9"] == "" then
            object["field9"] = nil
        end
        if object["field9"] then
            object["field9"] = JSON.parse(object["field9"])
        end

        # ------------------------------------
        # field9, NxBalls

        object["field13"] = JSON.parse(object["field13"] || "null")

        # ------------------------------------

        if object["mikuType"] == "NxTodo" then
            object["nx113"] = JSON.parse(object["field1"])
            return object
        end
        if object["mikuType"] == "NxAnniversary" then
            object["startdate"]           = object["field1"]
            object["repeatType"]          = object["field2"]
            object["lastCelebrationDate"] = object["field3"]
            return object
        end
        if object["mikuType"] == "Wave" then
            object["nx46"]                = JSON.parse(object["field1"])
            object["lastDoneDateTime"]    = object["field4"]
            object["nx113"]               = JSON.parse(object["field5"])
            object["onlyOnDays"]          = JSON.parse(object["field6"])
            return object
        end
        if object["mikuType"] == "TxManualCountDown" then
            object["dailyTarget"]         = object["field1"].to_i
            object["date"]                = object["field2"]
            object["counter"]             = object["field3"].to_i
            object["lastUpdatedUnixtime"] = object["field4"].to_i
            return object
        end
        if object["mikuType"] == "NxTimeCommitment" then
            object["resetTime"] = object["field2"].to_i
            object["field3"]    = object["field3"].to_f
            return object
        end
        if object["mikuType"] == "NxTimeCapsule" then
            object["field1"] = object["field1"].to_f
            return object
        end
        if object["mikuType"] == "NxDrop" then
            return object
        end
        if object["mikuType"] == "NxTop" then
            return object
        end
        puts JSON.pretty_generate(object)
        raise "(error: 002d8744-e34d-4307-b573-73a195a9c7ac)"
    end

    # ObjectStore1ItemObjectsTranslation::itemToDatabaseObject(item)
    def self.itemToDatabaseObject(item)

        item["field7"] = (item["field7"] || 0).to_f

        if item["field9"] then
            item["field9"] = JSON.generate(item["field9"])
        end

        item["field13"] = JSON.generate(item["field13"])

        if item["mikuType"] == "NxTodo" then
            item["field1"] = JSON.generate(item["nx113"])
            return item
        end
        if item["mikuType"] == "NxAnniversary" then
            item["field1"] = item["startdate"]
            item["field2"] = item["repeatType"]
            item["field3"] = item["lastCelebrationDate"]
            return item
        end
        if item["mikuType"] == "Wave" then
            item["field1"] = JSON.generate(item["nx46"])
            item["field4"] = item["lastDoneDateTime"]
            item["field5"] = JSON.generate(item["nx113"])
            item["field6"] = JSON.generate(item["onlyOnDays"])
            return item
        end
        if item["mikuType"] == "TxManualCountDown" then
            item["field1"] = item["dailyTarget"]
            item["field2"] = item["date"]
            item["field3"] = item["counter"]
            item["field4"] = item["lastUpdatedUnixtime"]
            return item
        end
        if item["mikuType"] == "NxTimeCommitment" then
            item["field2"] = item["resetTime"]
            return item
        end
        if item["mikuType"] == "NxTimeCapsule" then
            return item
        end
        if item["mikuType"] == "NxTimeCapsule" then
            return item
        end
        if item["mikuType"] == "NxDrop" then
            return item
        end
        if item["mikuType"] == "NxTop" then
            return item
        end
        puts JSON.pretty_generate(item)
        raise "(error: 34432491-c0a8-45a2-a93c-8a7b132d027e)"
    end
end
