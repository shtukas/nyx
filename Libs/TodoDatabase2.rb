# encoding: UTF-8

class TodoDatabase2

    # ----------------------------------
    # Config

    # TodoDatabase2::cardinality()
    def self.cardinality()
        200
    end

    # TodoDatabase2::foldername()
    def self.foldername()
        "TodoDatabase2"
    end

    # ----------------------------------
    # Interface

    # TodoDatabase2::databaseQuery(querystring, bindings)
    def self.databaseQuery(querystring, bindings)
        objects = {}
        TodoDatabase2::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute(querystring, bindings) do |row|
                objects[row["uuid"]] = TodoDatabase2::rowToObject(row)
            end
            db.close
        }
        # Note that we used a hash instead of an array because we could easily have the same object appearing several times
        # It's one of the ways the multi instance distributed database can misbehave
        objects.values
    end

    # TodoDatabase2::commitItem(item)
    def self.commitItem(item)
        puts "TodoDatabase2::commitItem(#{JSON.pretty_generate(item)})"
        FileSystemCheck::fsck_MikuTypedItem(item, true)
        database_object = TodoDatabase2ItemObjectsTranslation::itemToDatabaseObject(item)
        TodoDatabase2::commitObject(database_object)
    end

    # TodoDatabase2::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        item = nil
        TodoDatabase2::filepaths().each{|filepath|
            object = TodoDatabase2::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
            next if object.nil?
            item = TodoDatabase2ItemObjectsTranslation::databaseObjectToItem(object)
            break if !item.nil?
        }
        item
    end

    # TodoDatabase2::set(uuid, attname, attvalue)
    def self.set(uuid, attname, attvalue)
        puts "TodoDatabase2::set(#{uuid}, #{attname}, #{attvalue})"
        TodoDatabase2::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "update objects set #{attname}=? where uuid=?", [attvalue, uuid]
            db.close
        }
    end

    # TodoDatabase2::getOrNull(uuid, attname)
    def self.getOrNull(uuid, attname)
        answer = nil
        TodoDatabase2::filepaths().each{|filepath|
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

    # TodoDatabase2::destroy(uuid)
    def self.destroy(uuid)
        puts "TodoDatabase2::destroy(#{uuid})"
        TodoDatabase2::filepaths().each{|filepath|
            TodoDatabase2::deleteObjectInFile(filepath, uuid)
        }
    end

    # ----------------------------------
    # Private

    # TodoDatabase2::databaseItems()
    def self.databaseItems()
        TodoDatabase2::databaseQuery("select * from objects", [])
            .map{|object| TodoDatabase2ItemObjectsTranslation::databaseObjectToItem(object) }
    end

    # *Database Schema*
    # TodoDatabase2::commitObject(object)
    def self.commitObject(object)
        # If we want to commit an object, we need to rewrite all the files in which it is (meaning deleting the object and renaming the file)
        # and put it into a new file.

        filepaths = TodoDatabase2::filepaths()

        filepath0 = TodoDatabase2::spawnNewDatabase()

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, payload, doNotShowUntil, field1, field2, field3, field4, field5, field6, field7, field8, field9, field10, field11, field12, field13) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], object["unixtime"], object["datetime"], object["description"], object["payload"], object["doNotShowUntil"], object["field1"], object["field2"], object["field3"], object["field4"], object["field5"], object["field6"], object["field7"], object["field8"], object["field9"], object["field10"], object["field11"], object["field12"], object["field13"]]
        db.close

        # Note that we made filepaths, before creating filepath0, so we are not going to delete the object that is being saved from the fie that was just created  
        filepaths.each{|filepath|
            TodoDatabase2::deleteObjectInFile(filepath, object["uuid"])
        }

        while TodoDatabase2::filepaths().size > TodoDatabase2::cardinality() do
            filepath1, filepath2 = TodoDatabase2::filepaths()
            TodoDatabase2::mergeFiles(filepath1, filepath2)
        end
    end

    # *Database Schema*
    # TodoDatabase2::rowToObject(row)
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
    # TodoDatabase2::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToDataCenter()}/#{TodoDatabase2::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid text primary key, mikuType text, unixtime float, datetime text, description text, payload text, doNotShowUntil float, field1 text, field2 text, field3 text, field4 text, field5 text, field6 text, field7 text, field8 text, field9 text, field10 text, field11 text, field12 text, field13 float)", [])
        db.close
        filepath
    end

    # TodoDatabase2::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{TodoDatabase2::foldername()}")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # TodoDatabase2::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
    def self.getObjectFromFilepathByUUIDOrNull(filepath, uuid)
        object = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where uuid=?", [uuid]) do |row|
            object = TodoDatabase2::rowToObject(row)
        end
        db.close
        object
    end

    # TodoDatabase2::fileHasObject(filepath, uuid)
    def self.fileHasObject(filepath, uuid)
        !TodoDatabase2::getObjectFromFilepathByUUIDOrNull(filepath, uuid).nil?
    end

    # TodoDatabase2::fileIsEmpty(filepath)
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

    # TodoDatabase2::deleteObjectInFile(filepath, uuid)
    def self.deleteObjectInFile(filepath, uuid)
        if !TodoDatabase2::fileHasObject(filepath, uuid) then
            if TodoDatabase2::fileIsEmpty(filepath) then
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
        if TodoDatabase2::fileIsEmpty(filepath) then
            FileUtils.rm(filepath)
        else
            # Now we need to rename the file since it's contents have changed
            filepath2 = "#{Config::pathToDataCenter()}/#{TodoDatabase2::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
            FileUtils.mv(filepath, filepath2)
        end
        nil
    end

    # *Database Schema*
    # TodoDatabase2::mergeFiles(filepath1, filepath2)
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
        filepath3 = "#{Config::pathToDataCenter()}/#{TodoDatabase2::foldername()}/#{CommonUtils::timeStringL22()}.sqlite3"
        FileUtils.mv(filepath2, filepath3)
    end
end

class TodoDatabase2ItemObjectsTranslation

    # TodoDatabase2ItemObjectsTranslation::databaseObjectToItem(object)
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

    # TodoDatabase2ItemObjectsTranslation::itemToDatabaseObject(item)
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

class Database2Data

    # Database2Data::itemsForMikuType(mikuType)
    def self.itemsForMikuType(mikuType)
        TodoDatabase2::databaseQuery("select * from objects where mikuType=?", [mikuType])
            .map{|object| TodoDatabase2ItemObjectsTranslation::databaseObjectToItem(object) }
    end

    # Database2Data::listingItems()
    def self.listingItems()
        TodoDatabase2::databaseQuery("select * from objects where field12=?", ["true"])
            .map{|object| TodoDatabase2ItemObjectsTranslation::databaseObjectToItem(object) }
    end

    # Database2Data::the99Count()
    def self.the99Count()
        TodoDatabase2::filepaths()
            .map{|filepath|
                count = nil
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select count(*) as count from objects where mikuType=?", ["NxTodo"]) do |row|
                    count = row["count"]
                end
                db.close
                count
            }
            .inject(0, :+)
    end

    # Database2Data::itemIsListed(item)
    def self.itemIsListed(item)
        item["field12"] == "true"
    end
end

class Database2Engine

    # Database2Engine::activateItemForListing(item, trajectory)
    def self.activateItemForListing(item, trajectory)
        return if TodoDatabase2::getOrNull(item["uuid"], "field12") == "true"
        TodoDatabase2::set(item["uuid"], "field12", "true")
        TodoDatabase2::set(item["uuid"], "field13", JSON.generate(trajectory))
    end

    # Database2Engine::disactivateListing(item)
    def self.disactivateListing(item)
        TodoDatabase2::set(item["uuid"], "field7", 0)       # reset skipped until
        TodoDatabase2::set(item["uuid"], "field8", "")      # remove any lock
        TodoDatabase2::set(item["uuid"], "field12", "")     # remove listing flag
        TodoDatabase2::set(item["uuid"], "field13", "null") # remove trajectory
    end

    # Database2Engine::listingActivations()
    def self.listingActivations()

        Database2Data::itemsForMikuType("NxAnniversary")
            .select{|anniversary| Anniversaries::isOpenToAcknowledgement(anniversary) }
            .each{|item|
                next if Database2Data::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 6))
            }

        Database2Data::itemsForMikuType("NxTodo")
            .each{|item|
                next if Database2Data::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                next if item["field2"] != "ondate"
                next if Time.new.to_s[0, 10] < item["datetime"][0, 10]
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 6))
            }

        Database2Data::itemsForMikuType("NxTodo")
            .each{|item|
                next if Database2Data::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                next if item["field2"] != "triage"
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 24))
            }

        listedTodoSize = lambda {
            Database2Data::listingItems()
                .select{|item| item["mikuType"] == "NxTodo" }
                .size
        }
        if listedTodoSize.call() < 6 then
            item = Database2Data::itemsForMikuType("NxTodo")
                        .select{|item| !Database2Data::itemIsListed(item) }
                        .select{|item| DoNotShowUntil::isVisible(item) }
                        .select{|item| item["field2"] == "regular" }
                        .sample
            if item then
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 48))
            end
        end

        TxManualCountDowns::listingItems()
            .each{|item|
                next if Database2Data::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 2))
            }

        Database2Data::itemsForMikuType("Wave")
            .each{|item|
                next if (item["onlyOnDays"] and !item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()))
                next if Database2Data::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 18))
            }

        Database2Data::itemsForMikuType("NxTimeCommitment")
            .each{|item|
                next if Database2Data::itemsForMikuType("NxTimeCapsule").select{|capsule| capsule["field10"] == item["uuid"] }.size > 0
                next if (Time.new.to_i - item["resetTime"]) < 86400*7

                (0..6).each{|indx|
                    capsule = {
                        "uuid"        => SecureRandom.uuid,
                        "mikuType"    => "NxTimeCapsule",
                        "unixtime"    => Time.new.to_i,
                        "datetime"    => Time.new.utc.iso8601,
                        "field1"      => item["field3"].to_f/7,
                        "field10"     => item["uuid"]
                    }
                    puts JSON.pretty_generate(capsule)
                    TodoDatabase2::commitItem(capsule)
                    Database2Engine::activateItemForListing(capsule, Database2Engine::trajectory(Time.new.to_f + indx*86400, 24))
                }

                item["resetTime"] = Time.new.to_i

                TodoDatabase2::commitItem(item)
            }

        Database2Data::itemsForMikuType("NxTimeCapsule")
            .each{|item|
                next if Database2Data::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                # Time capsules are issued by NxTimeCommitment, and are actived at that moment
                # This exists in case we create one manually.
                Database2Engine::activateItemForListing(item, Database2Engine::trajectory(Time.new.to_f, 24))
            }
    end

    # Database2Engine::trajectory(activationunixtime, expectedTimeToCompletionInHours)
    def self.trajectory(activationunixtime, expectedTimeToCompletionInHours)
        {
            "activationunixtime"              => activationunixtime,
            "expectedTimeToCompletionInHours" => expectedTimeToCompletionInHours
        }
    end
end
