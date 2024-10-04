# encoding: UTF-8

class Marbles

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

    # Marbles::updateAttribute1(filepath, attrname, attrvalue)
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
    # Basic file IO, on uuids, may cause file renames

    # Marbles::updateAttribute2(uuid, attrname, attrvalue)
    def self.updateAttribute2(uuid, attrname, attrvalue)
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: 1e65dcd3) could not find filepath for uuid: #{uuid}"
        end
        Marbles::updateAttribute1(filepath, attrname, attrvalue)
    end

    # Marbles::putBlob2(uuid, datablob)
    def self.putBlob2(uuid, datablob)
        puts "writing datablob into uuid #{uuid}".yellow
        filepath = Marbles::find2(uuid)
        if filepath.nil? then
            raise "(error: b8e1a355) could not find filepath for uuid: #{uuid}"
        end
        Marbles::putBlob1(filepath, datablob)
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
    # Collection management

    # Take a uuid and find the file corresponding to that uuid or null

    # Marbles::find1(uuid) # filepath or null
    def self.find1(uuid)
        roots = [
            "#{Config::userHomeDirectory()}/Desktop",
            "#{Config::userHomeDirectory()}/Galaxy"
        ]
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

    # Marbles::filepathEnumeration()
    def self.filepathEnumeration()
        Enumerator.new do |filepaths|
            roots = [
                "#{Config::userHomeDirectory()}/Desktop",
                "#{Config::userHomeDirectory()}/Galaxy"
            ]
            Galaxy::locationEnumerator(roots).each{|filepath|
                if File.basename(filepath)[-6, 6] == ".nyx17" then
                    filepaths << filepath
                end
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
