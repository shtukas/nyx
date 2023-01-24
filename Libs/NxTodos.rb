# encoding: UTF-8

class NxTodosDatabase1

    # ----------------------------------
    # Interface

    # NxTodosDatabase1::objects()
    def self.objects()
        objects = {}
        NxTodosDatabase1::filepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from objects", []) do |row|
                objects[row["uuid"]] = {
                    "uuid"        => row["uuid"],
                    "mikuType"    => row["mikuType"],
                    "unixtime"    => row["unixtime"],
                    "datetime"    => row["datetime"],
                    "description" => row["description"],
                    "tcId"        => row["tcId"],
                    "tcPos"       => row["tcPos"],
                    "nx113"       => JSON.parse(row["nx113"]),
                }
            end
            db.close
        }
        # Note that we used a hash instead of an array because we could easily have the same object appearing several times
        # It's one of the ways the multi instance distributed database can misbehave
        objects.values
    end

    # NxTodosDatabase1::commit(object)
    def self.commit(object)
        # If we want to commit an object, we need to rewrite all the files in which it is (meaning deleting the object and renaming the file)
        # and put it into a new file.

        filepaths = NxTodosDatabase1::filepaths()

        filepath0 = NxTodosDatabase1::spawnNewDatabase()
        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, tcId, tcPos, nx113) values (?, ?, ?, ?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], object["unixtime"], object["datetime"], object["description"], object["tcId"], object["tcPos"], JSON.generate(object["nx113"])]
        db.close

        # Note that we made filepaths, before creating filepath0, so we are not going to delete the object that is being saved from the fie that was just created  
        filepaths.each{|filepath|
            NxTodosDatabase1::deleteObjectInFile(filepath, object["uuid"])
        }

        while NxTodosDatabase1::filepaths().size > 100 do
            filepath1, filepath2 = NxTodosDatabase1::filepaths()
            NxTodosDatabase1::mergeFiles(filepath1, filepath2)
        end
    end

    # NxTodosDatabase1::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        object = nil
        NxTodosDatabase1::filepaths().each{|filepath|
            object = NxTodosDatabase1::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
            break if !object.nil?
        }
        object
    end

    # NxTodosDatabase1::destroy(uuid)
    def self.destroy(uuid)
        NxTodosDatabase1::filepaths().each{|filepath|
            NxTodosDatabase1::deleteObjectInFile(filepath, uuid)
        }
    end

    # ----------------------------------
    # Private

    # NxTodosDatabase1::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToDataCenter()}/NxTodoXP2/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid text, mikuType text, unixtime float, datetime text, description text, tcId text, tcPos float, nx113 text)", [])
        db.close
        filepath
    end

    # NxTodosDatabase1::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodoXP2")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # NxTodosDatabase1::getObjectFromFilepathByUUIDOrNull(filepath, uuid)
    def self.getObjectFromFilepathByUUIDOrNull(filepath, uuid)
        object = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where uuid=?", [uuid]) do |row|
            object = {
                "uuid"        => row["uuid"],
                "mikuType"    => row["mikuType"],
                "unixtime"    => row["unixtime"],
                "datetime"    => row["datetime"],
                "description" => row["description"],
                "tcId"        => row["tcId"],
                "tcPos"       => row["tcPos"],
                "nx113"       => JSON.parse(row["nx113"]),
            }
        end
        db.close
        object
    end

    # NxTodosDatabase1::fileHasObject(filepath, uuid)
    def self.fileHasObject(filepath, uuid)
        !NxTodosDatabase1::getObjectFromFilepathByUUIDOrNull(filepath, uuid).nil?
    end

    # NxTodosDatabase1::fileIsEmpty(filepath)
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

    # NxTodosDatabase1::deleteObjectInFile(filepath, uuid)
    def self.deleteObjectInFile(filepath, uuid)
        if !NxTodosDatabase1::fileHasObject(filepath, uuid) then
            if NxTodosDatabase1::fileIsEmpty(filepath) then
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
        if NxTodosDatabase1::fileIsEmpty(filepath) then
            FileUtils.rm(filepath)
        else
            # Now we need to rename the file since it's contents have changed
            filepath2 = "#{Config::pathToDataCenter()}/NxTodoXP2/#{CommonUtils::timeStringL22()}.sqlite3"
            FileUtils.mv(filepath, filepath2)
        end
        nil
    end

    # NxTodosDatabase1::mergeFiles(filepath1, filepath2)
    def self.mergeFiles(filepath1, filepath2)
        db1 = SQLite3::Database.new(filepath1)
        db2 = SQLite3::Database.new(filepath2)

        # We move all the objects from db1 to db2

        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        db1.execute("select * from objects", []) do |row|
            db2.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, tcId, tcPos, nx113) values (?, ?, ?, ?, ?, ?, ?, ?)", [row["uuid"], row["mikuType"], row["unixtime"], row["datetime"], row["description"], row["tcId"], row["tcPos"], row["nx113"]] # We copy the nx113 as a string
        end

        db1.close
        db2.close

        # Let's now delete the first file 
        FileUtils.rm(filepath1)


        # And rename the second one
        filepath3 = "#{Config::pathToDataCenter()}/NxTodoXP2/#{CommonUtils::timeStringL22()}.sqlite3"
        FileUtils.mv(filepath2, filepath3)
    end
end

class NxTodosIO 

    # Utils

    # NxTodosIO::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/NxTodo"
    end

    # NxTodosIO::filepath(uuid)
    def self.filepath(uuid)
        "#{NxTodosIO::repositoryFolderPath()}/#{uuid}.json"
    end

    # Public Interface

    # NxTodosIO::commit(object)
    def self.commit(object)
        #FileSystemCheck::fsck_MikuTypedItem(object, true)
        #filepath = NxTodosIO::filepath(object["uuid"])
        #File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }

        NxTodosDatabase1::commit(object)
    end

    # NxTodosIO::getOrNull(uuid)
    def self.getOrNull(uuid)
        #filepath = "#{NxTodosIO::repositoryFolderPath()}/#{uuid}.json"
        #return nil if !File.exists?(filepath)
        #JSON.parse(IO.read(filepath))

        NxTodosDatabase1::getObjectByUUIDOrNull(uuid)
    end

    # NxTodosIO::items()
    def self.items()
        #LucilleCore::locationsAtFolder(NxTodosIO::repositoryFolderPath())
        #    .select{|filepath| filepath[-5, 5] == ".json" }
        #    .map{|filepath| JSON.parse(IO.read(filepath)) }

        NxTodosDatabase1::objects()
    end

    # NxTodosIO::destroy(uuid)
    def self.destroy(uuid)
        #filepath = NxTodosIO::filepath(uuid)
        #if File.exists?(filepath) then
        #    FileUtils.rm(filepath)
        #end

        NxTodosDatabase1::destroy(uuid)
    end
end

class NxTodos

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = CommonUtils::timeStringL22()
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        tcId = NxWTimeCommitments::interactivelySelectItem()["uuid"]
        tcPos = NxWTimeCommitments::interactivelyDecideProjectPosition(tcId)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "tcId"       => tcId,
            "tcPos" => tcPos
        }
        NxTodosIO::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(todo) #{item["description"]}#{nx113str}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # NxTodos::itemsForNxWTimeCommitment(tcId)
    def self.itemsForNxWTimeCommitment(tcId)
        NxTodosIO::items()
            .select{|item|
                item["tcId"] == tcId
            }
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::access(item)
    def self.access(item)
        puts NxTodos::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTodos::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTodosIO::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTodosIO::getOrNull(item["uuid"])
    end

    # NxTodos::probe(item)
    def self.probe(item)
        loop {
            system("clear")
            item = NxTodosIO::getOrNull(item["uuid"])
            puts NxTodos::toString(item)
            actions = ["access", "update description", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTodos::access(item)
            end
            if action == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                item["description"] = description
                NxTodosIO::commit(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of NxTodo '#{NxTodos::toString(item)}' ? ") then
                    NxTodosIO::destroy(item["uuid"])
                    return
                end
            end
        }
    end
end
