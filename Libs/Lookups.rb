# encoding: UTF-8

class Lookups

    # ----------------------------------
    # Interface

    # Lookups::getValueOrNull(foldername, uuid)
    def self.getValueOrNull(foldername, uuid)
        value = nil
        Lookups::filepaths(foldername).each{|filepath|
            value = Lookups::getValueInFileOrNull(filepath, uuid)
            break if !value.nil?
        }
        value
    end

    # Lookups::commit(foldername, uuid, value)
    def self.commit(foldername, uuid, value)
        # puts "Lookups::commit(#{foldername}, #{uuid}, #{JSON.generate(value)})"

        filepaths = Lookups::filepaths(foldername)

        filepath0 = Lookups::spawnNewDatabase(foldername)

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _values_ (uuid, value) values (?, ?)", [uuid, JSON.generate(value)]
        db.close

        # Note that we made filepaths, before creating filepath0, so we are not going to delete the value that is being saved from the fie that was just created  
        filepaths.each{|filepath|
            Lookups::deleteValueInFile(foldername, filepath, uuid)
        }

        while Lookups::filepaths(foldername).size > Lookups::capacity() do
            filepath1, filepath2 = Lookups::filepaths(foldername)
            Lookups::mergeFiles(foldername, filepath1, filepath2)
        end
    end

    # Lookups::destroy(foldername, uuid)
    def self.destroy(foldername, uuid)
        #puts "Lookups::destroy(#{foldername}, #{uuid})"
        Lookups::filepaths(foldername).each{|filepath|
            Lookups::deleteValueInFile(foldername, filepath, uuid)
        }
    end

    # ----------------------------------
    # Private (0)

    # Lookups::capacity()
    def self.capacity()
        50
    end

    # ----------------------------------
    # Private (1)

    # Lookups::spawnNewDatabase(foldername)
    def self.spawnNewDatabase(foldername)
        filepath = "#{Config::pathToDataCenter()}/#{foldername}/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _values_ (uuid text, value text)", [])
        db.close
        filepath
    end

    # Lookups::filepaths(foldername)
    def self.filepaths(foldername)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{foldername}")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # ----------------------------------
    # Private (2)

    # Lookups::getValueInFileOrNull(filepath, uuid)
    def self.getValueInFileOrNull(filepath, uuid)
        value = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _values_ where uuid=?", [uuid]) do |row|
            value = JSON.parse(row["value"])
        end
        db.close
        value
    end

    # Lookups::fileHasObject(filepath, uuid)
    def self.fileHasObject(filepath, uuid)
        !Lookups::getValueInFileOrNull(filepath, uuid).nil?
    end

    # Lookups::fileIsEmpty(filepath)
    def self.fileIsEmpty(filepath)
        count = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from _values_", []) do |row|
            count = row["_count_"]
        end
        db.close
        count == 0
    end

    # Lookups::deleteValueInFile(foldername, filepath, uuid)
    def self.deleteValueInFile(foldername, filepath, uuid)
        if !Lookups::fileHasObject(filepath, uuid) then
            if Lookups::fileIsEmpty(filepath) then
                FileUtils.rm(filepath)
            end
            return
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _values_ where uuid=?", [uuid]
        db.close
        if Lookups::fileIsEmpty(filepath) then
            FileUtils.rm(filepath)
        else
            # Now we need to rename the file since it's contents have changed
            filepath2 = "#{Config::pathToDataCenter()}/#{foldername}/#{CommonUtils::timeStringL22()}.sqlite3"
            FileUtils.mv(filepath, filepath2)
        end
        nil
    end

    # Lookups::mergeFiles(foldername, filepath1, filepath2)
    def self.mergeFiles(foldername, filepath1, filepath2)

        filepath3 = ObjectStore2::spawnNewDatabase(foldername)

        db3 = SQLite3::Database.new(filepath3)


        db1 = SQLite3::Database.new(filepath1)
        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        db1.execute("select * from _values_", []) do |row|
            db3.execute "insert into _values_ (uuid, value) values (?, ?)", [row["uuid"], row["value"]] # we copy the value as string
        end
        db1.close

        db2 = SQLite3::Database.new(filepath2)
        db2.busy_timeout = 117
        db2.busy_handler { |count| true }
        db2.results_as_hash = true
        db2.execute("select * from _values_", []) do |row|
            db3.execute "insert into _values_ (uuid, value) values (?, ?)", [row["uuid"], row["value"]] # we copy the value as string
        end
        db2.close

        db3.close

        FileUtils.rm(filepath1)
        FileUtils.rm(filepath2)
    end
end
