class StargateCentralDataBlobs

    # StargateCentralDataBlobs::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central"
    end

    # StargateCentralDataBlobs::propagateDatablobs(folderpath1, folderpath2)
    def self.propagateDatablobs(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            filename = File.basename(path)
            targetfolderpath = "#{folderpath2}/#{filename[7, 2]}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            next if File.exist?(targetfilepath)
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying datablob: #{filename}"
            FileUtils.cp(path, targetfilepath)
        end
    end

    # StargateCentralDataBlobs::propagateDatablobsWithPrimaryDeletion(folderpath1, folderpath2)
    def self.propagateDatablobsWithPrimaryDeletion(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            filename = File.basename(path)
            targetfolderpath = "#{folderpath2}/#{filename[7, 2]}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            if File.exist?(targetfilepath) then
                FileUtils.rm(path)
                next
            end
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying datablob: #{filename}"
            FileUtils.cp(path, targetfilepath)
            FileUtils.rm(path)
        end
    end
end

class StargateCentralInbox

    # StargateCentralInbox::pathToDatabase()
    def self.pathToDatabase()
        "#{StargateCentralDataBlobs::pathToCentral()}/events-inbox.sqlite3"
    end

    # StargateCentralInbox::writeEvent(uuid, unixtime, event)
    def self.writeEvent(uuid, unixtime, event)
        #puts "StargateCentralInbox::writeEvent(#{uuid}, #{unixtime}, #{JSON.pretty_generate(event)})"
        db = SQLite3::Database.new(StargateCentralInbox::pathToDatabase())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.execute "insert into _events_ (_uuid_, _unixtime_, _event_) values (?, ?, ?)", [uuid, unixtime, JSON.generate(event)]
        db.close
    end

    # StargateCentralInbox::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(StargateCentralInbox::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _events_ order by _unixtime_=?") do |row|
            answer << row
        end
        db.close
        answer
    end

    # StargateCentralInbox::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        db = SQLite3::Database.new(StargateCentralInbox::pathToDatabase())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.close
    end
end

class StargateCentralObjects

    # StargateCentralObjects::pathToObjectsDatabase()
    def self.pathToObjectsDatabase()
        "#{StargateCentralDataBlobs::pathToCentral()}/objects.sqlite3"
    end

    # StargateCentralObjects::objects()
    def self.objects()
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_") do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # StargateCentralObjects::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # StargateCentralObjects::commit(object)
    def self.commit(object)
        raise "(error: ee5c0d42-685e-433a-9d5b-c043494f19ff, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: a98ef432-f4f5-43e2-82ba-2edafa505a8d, missing attribute mikuType)" if object["mikuType"].nil?

        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
    end

    # StargateCentralObjects::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end

class StargateCuration

    # StargateCuration::inboxToObjects()
    def self.inboxToObjects()
        StargateCentralInbox::getRecords().each{|record|

            puts "StargateCuration::inboxToObjects(): inbox record: #{JSON.pretty_generate(record)}"

            event = JSON.parse(record["_event_"])

            puts "StargateCuration::inboxToObjects(): event: #{JSON.pretty_generate(event)}"

            if event["lxGenealogyAncestors"].nil? then
                # We are going to ignore this event because it is not well formed.
                StargateCentralInbox::deleteRecord(record["_uuid_"])
                next
            end

            existingCentralObject = StargateCentralObjects::getObjectByUUIDOrNull(event["uuid"])

            puts "existingCentralObject: #{JSON.pretty_generate(existingCentralObject)}"

            if existingCentralObject.nil? then
                StargateCentralObjects::commit(event)
                StargateCentralInbox::deleteRecord(record["_uuid_"])
                next
            end

            if existingCentralObject.to_s == event.to_s then
                StargateCentralInbox::deleteRecord(record["_uuid_"])
                next
            end

            if Genealogy::object1ShouldBeReplacedByObject2(existingCentralObject, event) then
                StargateCentralObjects::commit(event)
                StargateCentralInbox::deleteRecord(record["_uuid_"])
                next
            end

            raise "(error: 986cd6ef-01cf-41bc-b789-8189bdb0fae1) I don't know how to handle this case"
        }
    end
end
