
# create table objects (uuid string primary key, mikuType string, object string)
# File naming convention: <l22>,<l22>.sqlite

class N3Objects

    # The primary version of this file is in catalyst

    # --------------------------------------
    # Utils

    IndexFileCountBaseControl = 50

    # N3Objects::folderpath()
    def self.folderpath()
        "#{Config::pathToNyx()}/N3Objects"
    end

    # N3Objects::getExistingFilepathsSorted()
    def self.getExistingFilepathsSorted()
        LucilleCore::locationsAtFolder("#{N3Objects::folderpath()}")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
            .sort
    end

    # N3Objects::renameFile(filepath)
    def self.renameFile(filepath)
        filepathv2 = "#{N3Objects::folderpath()}/#{File.basename(filepath)[0, 22]}@#{CommonUtils::timeStringL22()}.sqlite3"
        FileUtils.mv(filepath, filepathv2)
    end

    # N3Objects::fileCardinal(filepath)
    def self.fileCardinal(filepath)
        count = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from objects", []) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # N3Objects::fileCarries(filepath, uuid)
    def self.fileCarries(filepath, uuid)
        flag = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select uuid from objects where uuid=?", [uuid]) do |row|
            flag = true
        end
        db.close
        flag
    end

    # N3Objects::deleteAtFilepath(filepath, uuid)
    def self.deleteAtFilepath(filepath, uuid)
        return if !N3Objects::fileCarries(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from objects where uuid=?", [uuid]
        db.close
        if N3Objects::fileCardinal(filepath) > 0 then
            N3Objects::renameFile(filepath)
        else
            FileUtils.rm(filepath)
        end
    end

    # N3Objects::deleteAtFiles(filepaths, uuid)
    def self.deleteAtFiles(filepaths, uuid)
        filepaths.each{|filepath|
            N3Objects::deleteAtFilepath(filepath, uuid)
        }
    end

    # N3Objects::getSmallestFileAmongTheseFilepaths(filepaths)
    def self.getSmallestFileAmongTheseFilepaths(filepaths)
        raise "(error: e7b2035c-fba4-4212-91f8-b9e71c1eb3e2)" if filepaths.empty?
        filepaths
            .map{|filepath|
                {
                    "filepath" => filepath,
                    "size"     => File.size(filepath)
                }
            }
            .sort{|p1, p2| p1["size"] <=> p2["size"] }
            .first["filepath"]
    end

    # N3Objects::selectSmallestFileAndTheNext()
    def self.selectSmallestFileAndTheNext()
        filepaths = N3Objects::getExistingFilepathsSorted()
        filepaths.pop
        filepath1 = N3Objects::getSmallestFileAmongTheseFilepaths(filepaths)
        filepaths = N3Objects::getExistingFilepathsSorted()
        while filepaths.include?(filepath1) do
            filepaths.shift
        end
        filepath2 = filepaths.first
        [filepath1, filepath2]
    end

    # N3Objects::fileManagement()
    def self.fileManagement()

        if N3Objects::getExistingFilepathsSorted().size > IndexFileCountBaseControl * 2 then

            puts "N3Objects file management".green

            while N3Objects::getExistingFilepathsSorted().size > IndexFileCountBaseControl do

                # We are taking the first two files (therefore the two oldest files and emptying the oldest)
                filepath1, filepath2 = N3Objects::selectSmallestFileAndTheNext()

                uuidsAtDB = lambda {|db|
                    uuids = []
                    db.busy_timeout = 117
                    db.busy_handler { |count| true }
                    db.results_as_hash = true
                    db.execute("select uuid from objects", []) do |row|
                        uuids << row["uuid"]
                    end
                    uuids
                }

                db1 = SQLite3::Database.new(filepath1)
                db2 = SQLite3::Database.new(filepath2)

                # We move all the objects from db1 to db2

                uuids2 = uuidsAtDB.call(db2)

                db1.busy_timeout = 117
                db1.busy_handler { |count| true }
                db1.results_as_hash = true
                db1.execute("select * from objects", []) do |row|
                    next if uuids2.include?(row["uuid"]) # The assumption is that the one in file2 is newer
                    db2.execute "insert into objects (uuid, owner, mikuType, object) values (?, ?, ?, ?)", [row["uuid"], row["owner"], row["mikuType"], row["object"]] # we copy object as encoded json
                end

                db1.close
                db2.close

                # Let's now delete the two files
                FileUtils.rm(filepath1)
                N3Objects::renameFile(filepath2)
            end
        end
    end

    # N3Objects::update(object)
    def self.update(object)

        object["n3timestamp"] = Time.new.to_f

        # Make a record of the existing files
        filepathszero = N3Objects::getExistingFilepathsSorted()

        # Make a new file for the object
        filepath = "#{N3Objects::folderpath()}/#{CommonUtils::timeStringL22()}@#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid string primary key, owner string, mikuType string, object string)", [])
        db.execute "insert into objects (uuid, owner, mikuType, object) values (?, ?, ?, ?)", [object["uuid"], object["owner"], object["mikuType"], JSON.generate(object)]
        db.close

        # Remove the object from the previously existing files
        N3Objects::deleteAtFiles(filepathszero, object["uuid"])
    end

    # N3Objects::getMikuTypeAtFile(mikuType, filepath)
    def self.getMikuTypeAtFile(mikuType, filepath)
        objects = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where mikuType=?", [mikuType]) do |row|
            objects << JSON.parse(row["object"])
        end
        db.close
        objects
    end

    # N3Objects::getSphereAtFile(owner, filepath)
    def self.getSphereAtFile(owner, filepath)
        objects = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where owner=?", [owner]) do |row|
            objects << JSON.parse(row["object"])
        end
        db.close
        objects
    end

    # N3Objects::getAtFilepathOrNull(uuid, filepath)
    def self.getAtFilepathOrNull(uuid, filepath)
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

    # --------------------------------------
    # Interface

    # N3Objects::commit(object)
    def self.commit(object)
        if object["uuid"].nil? then
            raise "object is missing uuid: #{JSON.pretty_generate(object)}"
        end
        if object["mikuType"].nil? then
            raise "object is missing mikuType: #{JSON.pretty_generate(object)}"
        end
        object["n3timestamp"] = Time.new.to_f
        N3Objects::update(object["uuid"], object)
    end

    # N3Objects::getOrNull(uuid)
    def self.getOrNull(uuid)
        objects = []
        N3Objects::getExistingFilepathsSorted().each{|filepath|
            objects << N3Objects::getAtFilepathOrNull(uuid, filepath)
        }
        objects
            .compact
            .sort_by{|object| object["n3timestamp"] }
            .reverse # oldest one is now first
            .first
    end

    # N3Objects::getMikuType(mikuType)
    def self.getMikuType(mikuType)
        objects = []
        N3Objects::getExistingFilepathsSorted().each{|filepath|
            N3Objects::getMikuTypeAtFile(mikuType, filepath).each{|object|
                objects << object
            }
        }
        objects
            .sort_by{|object| object["n3timestamp"] } # oldest first
            .reduce({}){|data, ob|
                data[ob["uuid"]] = ob # given the order in which they are presented, newer ones will override older ones
                data
            }
            .values
    end

    # N3Objects::getSphere(owner)
    def self.getSphere(owner)
        objects = []
        N3Objects::getExistingFilepathsSorted().each{|filepath|
            N3Objects::getSphereAtFile(owner, filepath).each{|object|
                objects << object
            }
        }
        objects
            .sort_by{|object| object["n3timestamp"] } # oldest first
            .reduce({}){|data, ob|
                data[ob["uuid"]] = ob # given the order in which they are presented, newer ones will override older ones
                data
            }
            .values
    end

    # N3Objects::getall()
    def self.getall()
        objects = []
        N3Objects::getExistingFilepathsSorted().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from objects", []) do |row|
                objects << JSON.parse(row["object"])
            end
            db.close
        }
        objects
            .sort_by{|object| object["n3timestamp"] } # oldest first
            .reduce({}){|data, ob|
                data[ob["uuid"]] = ob # given the order in which they are presented, newer ones will override older ones
                data
            }
            .values
    end

    # N3Objects::destroy(uuid)
    def self.destroy(uuid)
        filepaths = N3Objects::getExistingFilepathsSorted()
        N3Objects::deleteAtFiles(filepaths, uuid)
    end
end
