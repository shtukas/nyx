# encoding: UTF-8

$DATABASE_CACHE = {}

class ObjectStore2

    # ----------------------------------
    # Interface

    # ObjectStore2::objects(foldername)
    def self.objects(foldername)
        objects = []
        ObjectStore2::filepaths(foldername).each{|filepath|
            ObjectStore2::objectsInFile(filepath).each{|object|
                objects << object
            }
        }
        objects
    end

    # ObjectStore2::getOrNull(foldername, uuid)
    def self.getOrNull(foldername, uuid)
        object = nil
        ObjectStore2::filepaths(foldername).each{|filepath|
            object = ObjectStore2::getObjectInFileOrNull(filepath, uuid)
            break if !object.nil?
        }
        object
    end

    # ObjectStore2::commit(foldername, object)
    def self.commit(foldername, object)
        puts "ObjectStore2::commit(#{foldername}, #{JSON.pretty_generate(object)})"

        # If we want to commit an object, we need to rewrite all the files in which it is (meaning deleting the object and renaming the file)
        # and put it into a new file.

        filepaths = ObjectStore2::filepaths(foldername)

        filepath0 = ObjectStore2::spawnNewDatabase(foldername)

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, object) values (?, ?, ?, ?, ?, ?)", [object["uuid"], object["mikuType"], object["unixtime"], object["datetime"], object["description"], JSON.generate(object)]
        db.close

        # Note that we made filepaths, before creating filepath0, so we are not going to delete the object that is being saved from the fie that was just created  
        filepaths.each{|filepath|
            ObjectStore2::deleteObjectInFile(foldername, filepath, object["uuid"])
        }

        while ObjectStore2::filepaths(foldername).size > ObjectStore2::capacity() do
            filepath1, filepath2 = ObjectStore2::filepaths(foldername)
            ObjectStore2::mergeFiles(foldername, filepath1, filepath2)
        end
    end

    # ObjectStore2::destroy(foldername, uuid)
    def self.destroy(foldername, uuid)
        puts "ObjectStore2::destroy(#{foldername}, #{uuid})"
        ObjectStore2::filepaths(foldername).each{|filepath|
            ObjectStore2::deleteObjectInFile(foldername, filepath, uuid)
        }
    end

    # ----------------------------------
    # Private (0)

    # ObjectStore2::capacity()
    def self.capacity()
        50
    end

    # ----------------------------------
    # Private (1)

    # ObjectStore2::spawnNewDatabase(foldername) # filepath
    def self.spawnNewDatabase(foldername)
        filepath = "#{Config::pathToDataCenter()}/#{foldername}/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid text, mikuType text, unixtime float, datetime text, description text, object text)", [])
        db.close
        filepath
    end

    # ObjectStore2::filepaths(foldername)
    def self.filepaths(foldername)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{foldername}")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # ----------------------------------
    # Private (2)

    # ObjectStore2::getObjectInFileOrNull(filepath, uuid)
    def self.getObjectInFileOrNull(filepath, uuid)
        object = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where uuid=?", [uuid]) do |row|
            object = JSON.parse(row["object"])
        end
        db.close
        object
    end

    # ObjectStore2::fileHasObject(filepath, uuid)
    def self.fileHasObject(filepath, uuid)
        !ObjectStore2::getObjectInFileOrNull(filepath, uuid).nil?
    end

    # ObjectStore2::fileIsEmpty(filepath)
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

    # ObjectStore2::deleteObjectInFile(foldername, filepath, uuid)
    def self.deleteObjectInFile(foldername, filepath, uuid)
        if !ObjectStore2::fileHasObject(filepath, uuid) then
            if ObjectStore2::fileIsEmpty(filepath) then
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
        if ObjectStore2::fileIsEmpty(filepath) then
            FileUtils.rm(filepath)
        else
            # Now we need to rename the file since it's contents have changed
            filepath2 = "#{Config::pathToDataCenter()}/#{foldername}/#{CommonUtils::timeStringL22()}.sqlite3"
            FileUtils.mv(filepath, filepath2)
        end
        nil
    end

    # ObjectStore2::mergeFiles(foldername, filepath1, filepath2)
    def self.mergeFiles(foldername, filepath1, filepath2)

        filepath3 = ObjectStore2::spawnNewDatabase(foldername)

        db3 = SQLite3::Database.new(filepath3)

        # We move all the objects from db1 to db3

        db1 = SQLite3::Database.new(filepath1)
        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        db1.execute("select * from objects", []) do |row|
            db3.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, object) values (?, ?, ?, ?, ?, ?)", [row["uuid"], row["mikuType"], row["unixtime"], row["datetime"], row["description"], row["object"]] # we copy the object as string
        end
        db1.close

        # We move all the objects from db2 to db3

        db2 = SQLite3::Database.new(filepath2)
        db2.busy_timeout = 117
        db2.busy_handler { |count| true }
        db2.results_as_hash = true
        db2.execute("select * from objects", []) do |row|
            db3.execute "insert into objects (uuid, mikuType, unixtime, datetime, description, object) values (?, ?, ?, ?, ?, ?)", [row["uuid"], row["mikuType"], row["unixtime"], row["datetime"], row["description"], row["object"]] # we copy the object as string
        end
        db2.close

        db3.close

        # Let's now delete the two files
        FileUtils.rm(filepath1)
        FileUtils.rm(filepath2)
    end

    # ObjectStore2::objectsInFile(filepath)
    def self.objectsInFile(filepath)
        if $DATABASE_CACHE[filepath] then
            return $DATABASE_CACHE[filepath].map{|item| item.clone }
        end
        objects = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects", []) do |row|
            objects << JSON.parse(row["object"])
        end
        db.close
        $DATABASE_CACHE[filepath] = objects
        objects
    end
end
