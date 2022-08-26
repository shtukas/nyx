
class DxF1

    # DxF1::pathToRepository()
    def self.pathToRepository()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/DxF1s"
    end

    # DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
    def self.filepathIfExistsOrNullNoSideEffect(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        folderpath = "#{DxF1::pathToRepository()}/#{sha1[0, 2]}"
        return nil if !File.exists?(folderpath)
        filepath = "#{folderpath}/#{sha1}.dxf1.sqlite3"
        return nil if !File.exists?(filepath)
        filepath
    end

    # DxF1::filepath(objectuuid)
    def self.filepath(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        folderpath = "#{DxF1::pathToRepository()}/#{sha1[0, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{sha1}.dxf1.sqlite3"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table _dxf1_ (_objectuuid_ text, _eventuuid_ text primary key, _eventTime_ float, _eventType_ text, _name_ text, _value_ blob)", [])
            db.close
        end
        filepath
    end

    # DxF1::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
        if objectuuid.nil? then
            raise "(error: a3202192-2d16-4f82-80e9-a86a18d407c8)"
        end
        if eventuuid.nil? then
            raise "(error: 1025633f-b0aa-42ed-9751-b5f87af23450)"
        end
        if eventTime.nil? then
            raise "(error: 9a6caf6b-fa31-4fda-b963-f0c04f4e50a2)"
        end
        if attname.nil? then
            raise "(error: 0b103332-556d-4043-9cdd-81cf70b7a289)"
        end
        if attvalue.nil? then
            raise "(error: db06a417-68d1-471d-888f-9e497b268750)"
        end

        filepath = DxF1::filepath(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, "attribute", attname, attvalue]
        db.close

        TheIndex::updateIndexAtObjectAttempt(objectuuid)
        SystemEvents::publishDxF1OnCommsline(objectuuid)
    end

    # DxF1::setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "DxF1::setAttribute1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        DxF1::setAttribute0(objectuuid, eventuuid, eventTime, attname, JSON.generate(attvalue))
    end

    # DxF1::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        DxF1::setAttribute1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # DxF1::getAttribute(objectuuid, attname)
    def self.getAttribute(objectuuid, attname)
        db = SQLite3::Database.new(DxF1::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _dxf1_ where _objectuuid_=? and _name_=? order by _eventTime_", [objectuuid, attname]) do |row|
            attvalue = JSON.parse(row["_value_"])
        end
        db.close
        attvalue
    end

    # DxF1::getProtoItemAtFilepathOrNull(filepath)
    def self.getProtoItemAtFilepathOrNull(filepath)

        # We can only do this because with the current conventions, there is only one objectuuid per DxF1 file.

        item = {}

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _dxf1_ where _eventType_=? order by _eventTime_", ["attribute"]) do |row|
            attname = row["_name_"]
            attvalue = JSON.parse(row["_value_"])
            item[attname] = attvalue
        end
        db.close
        
        if item["uuid"].nil? then
            item = nil
        end

        item
    end

    # DxF1::getProtoItemOrNull(objectuuid)
    def self.getProtoItemOrNull(objectuuid)
        filepath = DxF1::filepath(objectuuid)
        DxF1::getProtoItemAtFilepathOrNull(filepath)
    end

    # DxF1::objectIsAlive(objectuuid)
    def self.objectIsAlive(objectuuid)
        value = DxF1::getAttribute(objectuuid, "isAlive")
        return true if value.nil?
        value
    end

    # DxF1::deleteObjectLogicallyNoEvents(objectuuid)
    def self.deleteObjectLogicallyNoEvents(objectuuid)
        DxF1::setAttribute2(objectuuid, "isAlive", false)
    end

    # DxF1::deleteObjectLogically(objectuuid)
    def self.deleteObjectLogically(objectuuid)
        DxF1::deleteObjectLogicallyNoEvents(objectuuid)
        TheIndex::destroy(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEvent({
            "mikuType"   => "(object has been logically deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # DxF1::eventExistsAtDxF1(objectuuid, eventuuid)
    def self.eventExistsAtDxF1(objectuuid, eventuuid)
        filepath = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        return false if filepath.nil?
        answer = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _eventuuid_ from _dxf1_ where _eventuuid_=?", [eventuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # DxF1::setDatablob0(objectuuid, eventuuid, eventTime, nhash, blob)
    def self.setDatablob0(objectuuid, eventuuid, eventTime, nhash, blob)
        if objectuuid.nil? then
            raise "(error: 4cb2f34f-f334-41ca-938c-7e29e214d8a3)"
        end
        if eventuuid.nil? then
            raise "(error: d0f2df7e-37d7-4cc4-8fe2-1ee186872cf8)"
        end
        if eventTime.nil? then
            raise "(error: 11691766-db20-45d4-9423-f2edc2c3b411)"
        end
        if nhash.nil? then
            raise "(error: e45b162d-9805-4230-99c8-4cf32e011fbd)"
        end
        if blob.nil? then
            raise "(error: 216cce98-4f41-4a17-8a2b-4ad86c4316a9)"
        end

        # -----------------------------------------------------------------------
        # To avoid waste and because this is an event log and not a kv store, 
        # let's check whether this blob has already been stored or not.

        checkIsPresent = lambda {
            db = SQLite3::Database.new(DxF1::filepath(objectuuid))
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            isPresent = false
            # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
            db.execute("select * from _dxf1_ where _objectuuid_=? and _name_=? order by _eventTime_", [objectuuid, nhash]) do |row|
                storedblob = row["_value_"]
                computednhash = "SHA256-#{Digest::SHA256.hexdigest(storedblob)}"
                status = (computednhash == nhash)
                if !status then
                    puts "(error: 24b0dca9-9bf4-4cc9-a6db-82b68e6c0aad) incorrect blob in DxF1 file, exists but doesn't have the right nhash: #{nhash}".red
                    puts "eventuuid: #{row["_eventuuid_"]}"
                    puts "computed nhash: #{computednhash}"
                    puts "Not a problem because I am in the process to write a new one, but this is highly distressing, isn't it?"
                    isPresent = false
                    next
                end
                isPresent = true
            end
            # The value of `isPresent` now the value of the last record check if there was at least one and `false` otherwise.
            db.close
            isPresent
        }

        return if checkIsPresent.call()

        # -----------------------------------------------------------------------

        db = SQLite3::Database.new(DxF1::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, "datablob", nhash, blob]
        db.close

        SystemEvents::publishDxF1OnCommsline(objectuuid)
    end

    # DxF1::setDatablob1(objectuuid, nhash, blob)
    def self.setDatablob1(objectuuid, nhash, blob)
        puts "DxF1::setDatablob1(#{objectuuid}, #{nhash}, ...)"
        DxF1::setDatablob0(objectuuid, SecureRandom.uuid, Time.new.to_f, nhash, blob)
    end

    # DxF1::getDatablobOrNull(objectuuid, nhash)
    def self.getDatablobOrNull(objectuuid, nhash)
        db = SQLite3::Database.new(DxF1::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _dxf1_ where _objectuuid_=? and _name_=? order by _eventTime_", [objectuuid, nhash]) do |row|
            blob = row["_value_"]
        end
        db.close
        blob
    end
end

class DxF1Elizabeth

    def initialize(objectuuid)
        @objectuuid = objectuuid
    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        DxF1::setDatablob1(@objectuuid, nhash, blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        DxF1::getDatablobOrNull(@objectuuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 28540df3-d3f4-4575-98cf-cc35658d5048) could not find blob, nhash: #{nhash}"
        raise "(error: fc70765f-85f3-4edd-89d9-c11eea137ef8, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 8c2f7dc9-d2d2-4222-90fe-90a7d3884e80) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class Fx256

    # Fx256::edit(item) # item
    def self.edit(item) # item
        if item["mikuType"] == "TopLevel" then
            return TopLevel::edit(item)
        end

        if item["nx111"] then
            puts "You are trying to edit a nx111 carrier"
            puts "Follow: 9e0705fc-8637-47f9-9bce-29df79d05292"
            exit
            return TheIndex::getItemOrNull(uuid)
        end

        raise "(error: 402f0ee5-4bd1-4b73-a418-d16ac12760ca)"
    end
end

class FxSynchronisation
    # FxSynchronisation::sync()
    def self.sync()

        DxPureFileManagement::bufferOutFilepathsEnumerator().each{|dxBufferOutFilepath|
            sha1 = File.basename(dxBufferOutFilepath).gsub(".sqlite3", "")
            eGridFilepath = DxPureFileManagement::energyGridDriveFilepath(sha1)
            if File.exists?(eGridFilepath) then
                eGridSha1 = Digest::SHA1.file(eGridFilepath).hexdigest
                if File.basename(eGridFilepath) != "#{eGridSha1}.sqlite3" then
                puts "FxSynchronisation::sync()"
                    puts "    I am trying to move #{dxBufferOutFilepath}"
                    puts "    I found #{eGridFilepath}"
                    puts "    #{eGridFilepath} has a sha1 of #{eGridSha1}"
                    puts "    Which is an irregularity 🤔"
                    puts "    Exit"
                    exit
                end
            else
                puts "FxSynchronisation::sync() copy"
                puts "    #{dxBufferOutFilepath}"
                puts "    #{eGridFilepath}"
                FileUtils.cp(dxBufferOutFilepath, eGridFilepath)
            end
            xcacheFilepath = DxPureFileManagement::xcacheFilepath(sha1)
            if !File.exists?(xcacheFilepath) then
                puts "FxSynchronisation::sync() copy"
                puts "    #{dxBufferOutFilepath}"
                puts "    #{xcacheFilepath}"
                FileUtils.cp(dxBufferOutFilepath, xcacheFilepath)
            end
            puts "FxSynchronisation::sync() deleting"
            puts "    #{dxBufferOutFilepath}"
            FileUtils.rm(dxBufferOutFilepath)
        }
    end
end
