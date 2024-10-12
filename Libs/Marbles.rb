# encoding: UTF-8

class Marbles

    # Marbles::repository()
    def self.repository()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Marbles"
    end

    # --------------------------------------------------
    # Initialization

    # Take a filepath, assuming not pointing at an existing file, and 
    # return the filepath of a fully formed marble.

    # Marbles::initiate(filepath, uuid)
    def self.initiate(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("CREATE TABLE object (recorduuid string, recordTime float, attributeName string, attributeValue blob);", [])
        db.execute("CREATE TABLE datablobs (key string, datablob blob);", [])

        db.execute("insert into object (recorduuid, recordTime, attributeName, attributeValue) values (?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "uuid", JSON.generate(uuid)])
        db.execute("insert into object (recorduuid, recordTime, attributeName, attributeValue) values (?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "mikutype", JSON.generate("Sx0138")])
        db.execute("insert into object (recorduuid, recordTime, attributeName, attributeValue) values (?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "unixtime", JSON.generate(Time.new.to_i)])
        db.execute("insert into object (recorduuid, recordTime, attributeName, attributeValue) values (?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, "datetime", JSON.generate(Time.new.utc.iso8601)])

        db.commit
        db.close

        # TODO: rename the file and almost certainly move it
        # TODO: idea: do we really need to provide the path, we could generate the path randomly pointing at the forge and 
        #       then move the file to whereever we need it. 

        XCache::set("82cccf8a-7717-421a-9f1e-306a22c5d1d0:#{uuid}", filepath)

        filepath
    end

    # Marbles::destroy1(filepath)
    def self.destroy1(filepath)
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end

    # Marbles::normaliseFilepath(filepath1)
    def self.normaliseFilepath(filepath1)
        if !File.exist?(filepath1) then
            raise "(error: 0dc0c2e5) trying to Marbles::normaliseFilepath, filepath: #{filepath}"
        end
        filepath2 = "#{Marbles::repository()}/#{Digest::SHA1.file(filepath1).hexdigest[0, 16]}.nyx17"
        if filepath1 == filepath2 then
            return filepath1
        end
        FileUtils.mv(filepath1, filepath2)
        filepath2
    end

    # --------------------------------------------------
    # Basic file IO, on filepaths

    # Marbles::itemOrError(filepath)
    def self.itemOrError(filepath)
        if !File.exist?(filepath) then
            raise "(error: 2b581a78) trying to Marbles::itemOrError, filepath: #{filepath}"
        end
        item = {}
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from object order by recordTime", []) do |row|
            item[row["attributeName"]] = JSON.parse(row["attributeValue"])
        end
        db.close
        item
    end

    # Marbles::updateAttribute1(filepath, attrname, attrvalue) # filepath
    def self.updateAttribute1(filepath, attrname, attrvalue)
        if !File.exist?(filepath) then
            raise "(error: ebf92c7b) trying to Marbles::updateAttribute1, filepath: #{filepath}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("insert into object (recorduuid, recordTime, attributeName, attributeValue) values (?, ?, ?, ?)", [SecureRandom.uuid, Time.new.to_f, attrname, JSON.generate(attrvalue)])
        db.commit
        db.close
    end

    # Marbles::putBlob1(filepath, datablob)
    def self.putBlob1(filepath, datablob)
        puts "writing datablob into filepath #{filepath}".yellow
        if !File.exist?(filepath) then
            raise "(error: 4fc076db) trying to Marbles::putBlob1, filepath: #{filepath}"
        end
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from datablobs where key=?", [nhash])
        db.execute("insert into datablobs (key, datablob) values (?, ?)", [nhash, datablob])
        db.commit
        db.close
        nhash
    end

    # Marbles::getBlob1(filepath, nhash)
    def self.getBlob1(filepath, nhash)
        if !File.exist?(filepath) then
            raise "(error: 4fc076db) trying to Marbles::putBlob1, filepath: #{filepath}"
        end
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablobs where key=?", [nhash]) do |row|
            datablob = row["datablob"]
        end
        db.close
        datablob
    end

    # --------------------------------------------------
    # Finding

    # Take a uuid and find the file corresponding to that uuid or null

    # Marbles::reduce(filepath1, filepath2)
    def self.reduce(filepath1, filepath2)
        # This function takes two files, we are going to check that they have the same uuid
        # and merge them into a new file.
        uuid1 = Marbles::itemOrError(filepath1)["uuid"]
        uuid2 = Marbles::itemOrError(filepath2)["uuid"]
        if uuid1 != uuid2 then
            raise "(error: 74a580dd) cannot Marbles::reduce, with filepath1: #{filepath1}, filepath2: #{filepath2}; we have uuid1: #{uuid1} and uuid2: #{uuid2}"
        end
        puts "merging:"
        puts "    filepath1: #{filepath1}"
        puts "    filepath2: #{filepath2}"

        # We are creating a new file in the /tmp (filepath3), 

        filepath3 = "/tmp/#{SecureRandom.hex(10)}"
        db3 = SQLite3::Database.new(filepath3)
        db3.busy_timeout = 117
        db3.busy_handler { |count| true }
        db3.results_as_hash = true
        db3.transaction
        db3.execute("CREATE TABLE object (recorduuid string, recordTime float, attributeName string, attributeValue blob);", [])
        db3.execute("CREATE TABLE datablobs (key string, datablob blob);", [])
        db3.commit

        # then moving in the data from filepath1, into filepath3
        # then moving in the data from filepath2, into filepath3

        [filepath1, filepath2].each{|filepathx|
            dbx = SQLite3::Database.new(filepathx)
            dbx.busy_timeout = 117
            dbx.busy_handler { |count| true }
            dbx.results_as_hash = true
            dbx.execute("select * from object", []) do |row|
                db3.execute("delete from object where recorduuid=?", [row["recorduuid"]])
                db3.execute("insert into object (recorduuid, recordTime, attributeName, attributeValue) values (?, ?, ?, ?)", [row["recorduuid"], row["recordTime"], row["attributeName"], row["attributeValue"]])
            end
            dbx.execute("select * from datablobs", []) do |row|
                db3.execute("delete from datablobs where key=?", [row["key"]])
                db3.execute("insert into datablobs (key, datablob) values (?, ?)", [row["key"], row["datablob"]])
            end
            dbx.close
        }
        db3.close

        # then moving the new file to the correct place
        filepath4 = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Marbles/#{SecureRandom.hex}.nyx17"
        FileUtils.mv(filepath3, filepath4)

        # then deleting filepath1
        # then deleting filepath2
        FileUtils.rm(filepath1)
        FileUtils.rm(filepath2)
    end

    # Marbles::removeDuplicateItems()
    def self.removeDuplicateItems()
        structure1 = {}
        roots = Marbles::searchRoots()
        Galaxy::locationEnumerator(roots).each{|filepath|
            if File.basename(filepath)[-6, 6] == ".nyx17" then
                item = Marbles::itemOrError(filepath)
                uuid = item["uuid"]
                if structure1[uuid].nil? then
                    structure1[uuid] = []
                end
                structure1[uuid] << filepath
            end
        }
        structure1.values.each{|filepaths|
            if filepaths.size > 1 then
                filepath1 = filepaths[0]
                filepath2 = filepaths[1]
                Marbles::reduce(filepath1, filepath2)
            end
        }
    end

    # Marbles::searchRoots()
    def self.searchRoots()
        [
            "#{Config::userHomeDirectory()}/Desktop",
            "#{Config::userHomeDirectory()}/Galaxy"
        ]
    end

    # Marbles::find1(uuid) # filepath or null
    def self.find1(uuid)
        roots = Marbles::searchRoots()
        Galaxy::locationEnumerator(roots).each{|filepath|
            if File.basename(filepath)[-6, 6] == ".nyx17" then
                # We have a marble file, we now need to probe it to know if it's the file we are looking for
                item = Marbles::itemOrError(filepath)
                if item["uuid"] == uuid then
                    return filepath
                else
                    # We do not have the right file but something useful we can do is cache the information
                    # that we have acquired. And we will do that even if the information was already 
                    # cached.
                    XCache::set("82cccf8a-7717-421a-9f1e-306a22c5d1d0:#{item["uuid"]}", filepath)
                end
            end
        }
        nil
    end

    # Take a uuid and find the file corresponding to that uuid or null
    # Same as Marbles::find1 but use caching
    # Marbles::find2(uuid)
    def self.find2(uuid)
        filepath = XCache::getOrNull("82cccf8a-7717-421a-9f1e-306a22c5d1d0:#{uuid}")
        if filepath and File.exist?(filepath) then
            item = Marbles::itemOrError(filepath)
            if item["uuid"] == uuid then
                return filepath
            end
        end

        puts "brute forcing locating uuid #{uuid}".yellow
        filepath = Marbles::find1(uuid)

        if filepath then
            XCache::set("82cccf8a-7717-421a-9f1e-306a22c5d1d0:#{uuid}", filepath)
        end

        filepath
    end

    # --------------------------------------------------
    # Basic file IO, on uuids, may cause file renames

    # Marbles::updateAttribute2(uuid, attrname, attrvalue) # filepath
    def self.updateAttribute2(uuid, attrname, attrvalue)
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: 1e65dcd3) could not find filepath for uuid: #{uuid}"
        end
        Marbles::updateAttribute1(filepath, attrname, attrvalue)
        filepath = Marbles::normaliseFilepath(filepath)
        XCache::set("82cccf8a-7717-421a-9f1e-306a22c5d1d0:#{uuid}", filepath)
    end

    # Marbles::putBlob2(uuid, datablob)
    def self.putBlob2(uuid, datablob)
        puts "writing datablob into uuid #{uuid}".yellow
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: b8e1a355) could not find filepath for uuid: #{uuid}"
        end
        nhash = Marbles::putBlob1(filepath, datablob)
        filepath = Marbles::normaliseFilepath(filepath)
        XCache::set("82cccf8a-7717-421a-9f1e-306a22c5d1d0:#{uuid}", filepath)
        nhash
    end

    # Marbles::getBlob2(uuid, nhash)
    def self.getBlob2(uuid, nhash)
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: 4430e73c) could not find filepath for uuid: #{uuid}"
        end
        Marbles::getBlob1(filepath, nhash)
    end

    # Marbles::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: 7cf4b64d) could not find filepath for uuid: #{uuid}"
        end
        Marbles::itemOrError(filepath)
    end

    # Marbles::destroy2(uuid)
    def self.destroy2(uuid)
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: c4d367b7) could not find filepath for uuid: #{uuid}"
        end
        Marbles::destroy1(filepath)
    end

    # --------------------------------------------------
    # Collection

    # Marbles::filepathEnumeration()
    def self.filepathEnumeration()
        Enumerator.new do |filepaths|
            roots = Marbles::searchRoots()
            Galaxy::locationEnumerator(roots).each{|filepath|
                if File.basename(filepath)[-6, 6] == ".nyx17" then
                    filepaths << filepath
                end
            }
        end
    end

    # Marbles::itemEnumeratorFromDisk()
    def self.itemEnumeratorFromDisk()
        Enumerator.new do |items|
            Marbles::filepathEnumeration().each{|filepath|
                items << Marbles::itemOrError(filepath)
            }
        end
    end

end


class Elizabeth

    def initialize(uuid)
        # Very important. The uuid can be null. In which case we store in XCache.
        # This happen when we build a payload before the marble has been initialised.
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        # Very important. The uuid can be null. In which case we store in XCache.
        # This happen when we build a payload before the marble has been initialised.
        if @uuid then
            Marbles::putBlob2(@uuid, datablob)
        else
            nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
            XCache::set("2a46e9c0-7c50-4bf4-ab61-d5a1b8220cef:#{nhash}", datablob)
            nhash
        end
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)

        # Very important. The uuid can be null. In which case we store in XCache.
        # This happen when we build a payload before the marble has been initialised.

        datablob = nil

        # --------------------------------------------------------
        # Attempting to retrieve from Marble

        if @uuid then
            datablob = Marbles::getBlob2(@uuid, nhash)
        end

        if datablob and (nhash != "SHA256-#{Digest::SHA256.hexdigest(datablob)}") then
            datablob = nil
        end

        if datablob then
            return datablob
        end

        # --------------------------------------------------------
        # Attempting to retrieve from Datablobs

        datablob = Datablobs::getBlobOrNull(nhash)

        if datablob and (nhash != "SHA256-#{Digest::SHA256.hexdigest(datablob)}") then
            datablob = nil
        end

        if datablob and @uuid then
            Marbles::putBlob2(@uuid, datablob)
        end

        if datablob then
            return datablob
        end

        # --------------------------------------------------------
        # Attempting to retrieve from XCache

        datablob = XCache::getOrNull("2a46e9c0-7c50-4bf4-ab61-d5a1b8220cef:#{nhash}")

        if datablob and (nhash != "SHA256-#{Digest::SHA256.hexdigest(datablob)}") then
            datablob = nil
        end

        if datablob and @uuid then
            Marbles::putBlob2(@uuid, datablob)
        end

        datablob
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: ff339aa3-b7ea-4b92-a211-5fc1048c048b, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 900a9a53-66a3-4860-be5e-dffa7a88c66d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
