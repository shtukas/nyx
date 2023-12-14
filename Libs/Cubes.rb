# encoding: UTF-8

class Cubes

    # ----------------------------------------
    # File Management (1)

    # Cubes::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        filepath = "/tmp/#{SecureRandom.hex}"
        puts "> create item file: #{filepath}".yellow
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _cube_ (_recorduuid_ text primary key, _recordTime_ float, _recordType_ string, _name_ text, _value_ blob)", [])
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", "uuid", JSON.generate(uuid)]
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", "mikuType", JSON.generate(mikuType)]
        db.close
        Cubes::relocate(filepath)
    end

    # Cubes::existingFilepathOrNull(uuid)
    def self.existingFilepathOrNull(uuid)
        filepath = XCache::getOrNull("e0cd5f8b-b33e-4adc-a294-ac7909a8147e:#{uuid}")
        if filepath and File.exist?(filepath) then
            # We do not need to check the uuid of the file because of content addressing
            return filepath
        end

        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/Cubes")
            .select{|location| location[-14, 14] == ".nyx-cube" }
            .each{|filepath|
                u1 = Cubes::uuidFromFile(filepath)
                XCache::set("e0cd5f8b-b33e-4adc-a294-ac7909a8147e:#{u1}", filepath)
                if u1 == uuid then
                    return filepath
                end
            }

        nil
    end

    # Cubes::relocate(filepath1)
    def self.relocate(filepath1)
        folderpath2 = "#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/Cubes"
        filename2 = "#{Digest::SHA1.file(filepath1).hexdigest}.nyx-cube"
        filepath2 = "#{folderpath2}/#{filename2}"
        return filepath1 if (filepath1 == filepath2)
        puts "filepath1: #{filepath1}".yellow
        puts "filepath2: #{filepath2}".yellow
        FileUtils.mv(filepath1, filepath2)

        uuid = Cubes::uuidFromFile(filepath2)
        XCache::set("e0cd5f8b-b33e-4adc-a294-ac7909a8147e:#{uuid}", filepath2)

        filepath2
    end

    # ----------------------------------------
    # File Management (2)

    # Cubes::uuidFromFile(filepath)
    def self.uuidFromFile(filepath)
        if !File.exist?(filepath) then
            raise "(error: 1fe836ef-01a9-447e-87ee-11c3dcb9128f); filepath: #{filepath}"
        end
        uuid = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _cube_ where _recordType_=? and _name_=?", ["attribute", "uuid"]) do |row|
            uuid = JSON.parse(row["_value_"])
        end
        db.close
        if uuid.nil? then
            raise "(error: dc064375-fa98-453a-9fc8-c242c6a9a270): filepath: #{filepath}"
        end
        uuid
    end

    # Cubes::filepathToItem(filepath)
    def self.filepathToItem(filepath)
        raise "(error: 20013646-0111-4434-9d8f-9c90baca90a6)" if !File.exist?(filepath)
        return nil if filepath.nil?
        item = {}
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We extract the most recent value
        db.execute("select * from _cube_ where _recordType_=? order by _recordTime_", ["attribute"]) do |row|
            item[row["_name_"]] = JSON.parse(row["_value_"])
        end
        db.close
        item
    end

    # ----------------------------------------
    # Items

    # Cubes::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        Cubes::filepathToItem(filepath)
    end

    # Cubes::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        filepath = Cubes::existingFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: b2a27beb-7b23-4077-af2f-ba408ed37748); uuid: #{uuid}, attrname: #{attrname}, attrvalue: #{attrvalue}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", attrname, JSON.generate(attrvalue)]
        db.close
        Cubes::relocate(filepath)
        nil
    end

    # Cubes::getAttributeOrNull(uuid, attrname)
    def self.getAttributeOrNull(uuid, attrname)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        value = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We extract the most recent value
        db.execute("select * from _cube_ where _recordType_=? and _name_=? order by _recordTime_", ["attribute", attrname]) do |row|
            value = JSON.parse(row["_value_"])
        end
        db.close
        value
    end

    # Cubes::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        blob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _cube_ where _recordType_=? and _name_=?", ["datablob", nhash]) do |row|
            bx = row["_value_"]
            if "SHA256-#{Digest::SHA256.hexdigest(bx)}" == nhash then
                blob = bx
            end
        end
        db.close
        # We return a blob that was checked against the nhash
        # Also note that we allow for corrupted records before finding the right one.
        # See Cubes::putBlob, for more.
        blob
    end

    # Cubes::putBlob(uuid, blob)
    def self.putBlob(uuid, blob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        if bx = Cubes::getBlobOrNull(uuid, nhash) then
            return nhash
        end
        filepath = Cubes::existingFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: e6cea94f-1b92-46ad-96af-adf9ecbded1d); uuid: #{uuid}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # Unlike other implementations, we do not delete a possible existing record.
        # Either there was none, ot there was one, but it's in correct
        # Also, treating these files as happen only ensure that we can merge them without logical issues.
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "datablob", nhash, blob]
        db.close
        Cubes::relocate(filepath)
        nhash
    end

    # Cubes::destroy(uuid)
    def self.destroy(uuid)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return if filepath.nil?
        puts "> delete item file: #{filepath}".yellow
        FileUtils.rm(filepath)
    end

    # ----------------------------------------
    # Items

    # Cubes::items()
    def self.items()
        items = []
        Find.find("#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/Cubes") do |path|
            next if !path.include?(".nyx-cube")
            next if File.basename(path).start_with?('.') # .syncthing.82aafe48c87c22c703b32e35e614f4d7.nyx-cube.tmp 
            items << Cubes::filepathToItem(path)
        end
        items
    end

    # Cubes::mikuType(mikuType)
    def self.mikuType(mikuType)
        Cubes::items().select{|item| item["mikuType"] == mikuType }
    end
end

class Elizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Cubes::putBlob(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Cubes::getBlobOrNull(@uuid, nhash)
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
