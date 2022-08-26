
class DxF1

    # DxF1::pathToRepository()
    def self.pathToRepository()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/DxF1s"
    end

    # DxF1::filepathOrNullNoSideEffect(objectuuid)
    def self.filepathOrNullNoSideEffect(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        folderpath = "#{DxF1::pathToRepository()}/#{sha1[0, 2]}"
        return nil if !File.exists?(folderpath)
        "#{folderpath}/#{sha1}.dxf1.sqlite3"
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

    # DxF1::commit(objectuuid, eventuuid, eventTime, attname, attvalue) # row or null
    def self.commit(objectuuid, eventuuid, eventTime, attname, attvalue) 
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

    # DxF1::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "DxF1::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        DxF1::commit(objectuuid, eventuuid, eventTime, attname, JSON.generate(attvalue))
    end

    # DxF1::setJsonEncoded(objectuuid, attname, attvalue)
    def self.setJsonEncoded(objectuuid, attname, attvalue)
        DxF1::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # DxF1::getJsonDecodeOrNull(objectuuid, attname)
    def self.getJsonDecodeOrNull(objectuuid, attname)
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
        value = DxF1::getJsonDecodeOrNull(objectuuid, "isAlive")
        return true if value.nil?
        value
    end

    # DxF1::deleteObjectLogicallyNoEvents(objectuuid)
    def self.deleteObjectLogicallyNoEvents(objectuuid)
        DxF1::setJsonEncoded(objectuuid, "isAlive", false)
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

    # DxF1::broadcastObjectFile(objectuuid)
    def self.broadcastObjectFile(objectuuid)
        puts "todo: DxF1::broadcastObjectFile"
    end

    # DxF1::eventExistsAtDxF1(objectuuid, eventuuid)
    def self.eventExistsAtDxF1(objectuuid, eventuuid)
        filepath = DxF1::filepathOrNullNoSideEffect(objectuuid)
        return false if filepath.nil?
        answer = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select _eventuuid_ from _dxf1_", [eventuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end
end

class Fx256

    # Fx256::filepathOrNull(objectuuid)
    def self.filepathOrNull(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256/#{sha1[0, 1]}/#{sha1[1, 1]}"
        return nil if !File.exists?(folderpath)
        "#{folderpath}/Fx18.sqlite3"
    end

    # Fx256::edit(item) # item
    def self.edit(item) # item
        if item["mikuType"] == "TopLevel" then
            return TopLevel::edit(item)
        end

        if item["nx111"] then
            puts "You are trying to edit a nx111 carrier"
            puts "Follow: 9e0705fc-8637-47f9-9bce-29df79d05292"
            exit
            return DxF1::getProtoItemOrNull(uuid)
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
