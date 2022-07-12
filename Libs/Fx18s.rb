
class Fx18s

    # --------------------------------------------------------------

    # Fx18s::computeLocalFx18Filepath(objectuuid)
    def self.computeLocalFx18Filepath(objectuuid)
        "#{Config::pathToDataBankStargate()}/Fx18s/#{objectuuid}.fx18.sqlite3"
    end

    # Fx18s::constructNewFile(objectuuid) # location (That function constructs the database and creates the _fx18_ table)
    def self.constructNewFile(objectuuid)
        filepath = Fx18s::computeLocalFx18Filepath(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "create table _fx18_ (_eventuuid_ text primary key, _eventTime_ float, _eventData1_ blob, _eventData2_ blob, _eventData3_ blob, _eventData4_ blob, _eventData5_ blob);"
        db.close
    end

    # --------------------------------------------------------------

    # Fx18s::setAttribute(eventuuid, eventTime, objectuuid, attname, attvalue)
    def self.setAttribute(eventuuid, eventTime, objectuuid, attname, attvalue)
        
    end

    # Fx18s::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        
    end

    # Fx18s::getAttributeOrNull(objectuuid, attname)
    def self.getAttributeOrNull(objectuuid, attname)
        
    end

    # --------------------------------------------------------------

    # Fx18s::setsAdd(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value)
    def self.setsAdd(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value)
        
    end

    # Fx18s::setsAdd2(objectuuid, setuuid, itemuuid, value)
    def self.setsAdd2(objectuuid, setuuid, itemuuid, value)
        
    end

    # Fx18s::setsRemove(eventuuid, eventTime, objectuuid, setuuid, itemuuid)
    def self.setsRemove(eventuuid, eventTime, objectuuid, setuuid, itemuuid)
        
    end

    # Fx18s::setsRemove2(objectuuid, setuuid, itemuuid)
    def self.setsRemove2(objectuuid, setuuid, itemuuid)
        
    end

    # Fx18s::setsItems(objectuuid, setuuid)
    def self.setsItems(objectuuid, setuuid)
        
    end

    # --------------------------------------------------------------

    # Fx18s::putData(eventuuid, eventTime, objectuuid, key, data)
    def self.putData(eventuuid, eventTime, objectuuid, key, data)
        
    end

    # Fx18s::putData2(objectuuid, key, data)
    def self.putData2(objectuuid, key, data)
        
    end

    # Fx18s::getDataOrNull(objectuuid, key)
    def self.getDataOrNull(objectuuid, key)
        
    end
end
