
# encoding: UTF-8

class CoreDataTx

    # CoreDataTx::databaseFilepath()
    def self.databaseFilepath()
        "#{Utils::catalystDataCenterFolderpath()}/objects.sqlite3"
    end

    # CoreDataTx::insertRecord(objectId, schema, unixtime, description, payload1, payload2, payload3, payload4, payload5)
    def self.insertRecord(objectId, schema, unixtime, description, payload1, payload2, payload3, payload4, payload5)
        db = SQLite3::Database.new(CoreDataTx::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _objects_ where _objectId_=?", [objectId]
        db.execute "insert into _objects_ (_objectId_, _schema_, _unixtime_, _description_, _payload1_, _payload2_, _payload3_, _payload4_, _payload5_) values (?,?,?,?,?,?,?,?,?)", [objectId, schema, unixtime, description, payload1, payload2, payload3, payload4, payload5]
        db.commit 
        db.close
    end

    # CoreDataTx::delete(objectId)
    def self.delete(objectId)
        db = SQLite3::Database.new(CoreDataTx::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _objects_ where _objectId_=?", [objectId]
        db.commit 
        db.close
    end

    # CoreDataTx::rowToAppropriateObject(row)
    def self.rowToAppropriateObject(row)
        object = {
            "uuid"        => row["_objectId_"],
            "schema"      => row["_schema_"],
            "unixtime"    => row["_unixtime_"],
            "description" => row["_description_"],

            "payload1"    => row["_payload1_"],
            "payload2"    => row["_payload2_"],
            "payload3"    => row["_payload3_"],
            "payload4"    => row["_payload4_"],
            "payload5"    => row["_payload5_"],
        }

        if object["schema"] == "wave" then
            object["repeatType"]       = object["payload1"]
            object["repeatValue"]      = object["payload2"]
            object["lastDoneDateTime"] = object["payload3"]
            object["contentType"]      = object["payload4"]
            object["payload"]          = object["payload5"]
        end

        if object["schema"] == "anniversary" then
            object["startdate"]           = object["payload1"]
            object["repeatType"]          = object["payload2"]
            object["lastCelebrationDate"] = object["payload3"]
        end

        if object["schema"] == "quark" then
            object["contentType"]               = object["payload1"]
            object["payload"]                   = object["payload2"]
            object["air-traffic-control-agent"] = object["payload3"]
        end

        if object["schema"] == "workitem" then
            object["workItemType"]      = object["payload1"]
            object["trelloLink"]        = object["payload2"]
            object["prLink"]            = object["payload3"]
            object["gitBranch"]         = object["payload4"]
            object["directoryFilename"] = object["payload5"]
        end

        if object["schema"] == "project" then
            object["directoryFilename"]            = object["payload1"]
            object["timeCommitmentInHoursPerWeek"] = object["payload2"].to_f
        end

        object.delete("payload1")
        object.delete("payload2")
        object.delete("payload3")
        object.delete("payload4")
        object.delete("payload5")

        object
    end

    # CoreDataTx::getObjectByIdOrNull(objectId)
    def self.getObjectByIdOrNull(objectId)
        db = SQLite3::Database.new(CoreDataTx::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _objects_ where _objectId_=?" , [objectId] ) do |row|
            answer = CoreDataTx::rowToAppropriateObject(row)
        end
        db.close
        answer
    end

    # CoreDataTx::getObjectsBySchema(schema)
    def self.getObjectsBySchema(schema)
        db = SQLite3::Database.new(CoreDataTx::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _objects_ where _schema_=? order by _unixtime_" , [schema] ) do |row|
            answer << CoreDataTx::rowToAppropriateObject(row)
        end
        db.close
        answer
    end

    # CoreDataTx::supportedSchemas()
    def self.supportedSchemas()
        [
            "wave", 
            "anniversary",
            "quark",
            "workitem",
            "project"
        ]
    end

    # CoreDataTx::commit(object)
    def self.commit(object)

        raise "04d8079d-e804-48af-9a12-25cdec657112: #{object}" if !CoreDataTx::supportedSchemas().include?(object["schema"])

        hasBeenTransformed = false

        if object["schema"] == "wave" then
            object["payload1"] = object["repeatType"]
            object["payload2"] = object["repeatValue"]
            object["payload3"] = object["lastDoneDateTime"]
            object["payload4"] = object["contentType"]
            object["payload5"] = object["payload"]
            hasBeenTransformed = true
        end

        if object["schema"] == "anniversary" then
            object["payload1"] = object["startdate"]
            object["payload2"] = object["repeatType"]
            object["payload3"] = object["lastCelebrationDate"]
            object["payload4"] = nil
            object["payload5"] = nil
            hasBeenTransformed = true
        end

        if object["schema"] == "quark" then
            object["payload1"] = object["contentType"]
            object["payload2"] = object["payload"]
            object["payload3"] = object["air-traffic-control-agent"]
            object["payload4"] = nil
            object["payload5"] = nil
            hasBeenTransformed = true
        end

        if object["schema"] == "workitem" then
            object["payload1"] = object["workItemType"]
            object["payload2"] = object["trelloLink"]
            object["payload3"] = object["prLink"]
            object["payload4"] = object["gitBranch"]
            object["payload5"] = object["directoryFilename"]
            hasBeenTransformed = true
        end

        if object["schema"] == "project" then
            object["payload1"] = object["directoryFilename"]
            object["payload2"] = object["timeCommitmentInHoursPerWeek"]
            object["payload3"] = nil
            object["payload4"] = nil
            object["payload5"] = nil
            hasBeenTransformed = true
        end

        if !hasBeenTransformed then
            raise "f542f249-77db-4d4c-a984-3efa14e62fa1: #{object}"
        end

        CoreDataTx::insertRecord(object["uuid"], object["schema"], object["unixtime"], object["description"], object["payload1"], object["payload2"], object["payload3"], object["payload4"], object["payload5"])
    end
end
