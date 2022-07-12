
class Fx18s

    # --------------------------------------------------------------

    # Fx18s::computeLocalFx18Filepath(objectuuid)
    def self.computeLocalFx18Filepath(objectuuid)
        "#{Config::pathToDataBankStargate()}/Fx18s/#{objectuuid}.fx18.sqlite3"
    end

    # Fx18s::constructNewFile(objectuuid) # location (That function constructs the database and creates the _fx18_ table)
    def self.constructNewFile(objectuuid)
        filepath = Fx18s::computeLocalFx18Filepath(objectuuid)
        if File.exists?(filepath) then
            puts "operation: Fx18s::constructNewFile"
            puts "objectuuid: #{objectuuid}"
            puts "filepath: #{filepath}"
            raise "(error: a906e951-c38e-4b96-a6b4-0084df2ff854) file already exists"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _fx18_ (_eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob);"
        db.close
    end

    # Fx18s::acquireFilepath(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.acquireFilepath(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        Fx18s::computeLocalFx18Filepath(objectuuid)
    end

    # --------------------------------------------------------------

    # Fx18s::setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepath(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, "attribute", attname, attvalue]
        db.close
    end

    # Fx18s::setAttribute2(objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setAttribute2(objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
        Fx18s::setAttribute1(SecureRandom.uuid, Time.new.to_f, objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
    end

    # Fx18s::getAttributeOrNull(objectuuid, attname, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.getAttributeOrNull(objectuuid, attname, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # --------------------------------------------------------------

    # Fx18s::setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # Fx18s::setsAdd2(objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsAdd2(objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # Fx18s::setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # Fx18s::setsRemove2(objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsRemove2(objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # Fx18s::setsItems(objectuuid, setuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsItems(objectuuid, setuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # --------------------------------------------------------------

    # Fx18s::putData1(eventuuid, eventTime, objectuuid, key, data, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.putData1(eventuuid, eventTime, objectuuid, key, data, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # Fx18s::putData2(objectuuid, key, data, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.putData2(objectuuid, key, data, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end

    # Fx18s::getDataOrNull(objectuuid, key, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.getDataOrNull(objectuuid, key, shouldDownloadFileIfFoundOnRemoteDrive)
        
    end
end
