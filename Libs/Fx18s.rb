
class EnergyGridUniqueBlobs

    # EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
    def self.decideFilepathForUniqueBlob(nhash)
        filepath1 = "#{Config::pathToDataBankStargate()}/Data/#{nhash[7, 2]}/#{nhash}.data"
        folderpath1 = File.dirname(filepath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkdir(folderpath1)
        end
        filepath1
    end

    # EnergyGridUniqueBlobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath1 = EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
        File.open(filepath1, "w"){|f| f.write(blob) }
        nhash
    end

    # EnergyGridUniqueBlobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath1 = EnergyGridUniqueBlobs::decideFilepathForUniqueBlob(nhash)
        #puts filepath1.green
        if File.exists?(filepath1) then
            return IO.read(filepath1)
        end

        StargateCentral::askForInfinityAndFailIfNot()

        filepath1 = filepath1.gsub("#{Config::pathToDataBankStargate()}/Data", "#{StargateCentral::pathToCentral()}/Data")
        #puts filepath1.green
        if File.exists?(filepath1) then
            return IO.read(filepath1)
        end

        nil
    end
end

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

    # Fx18s::ensureFile(objectuuid)
    def self.ensureFile(objectuuid)
        filepath = Fx18s::computeLocalFx18Filepath(objectuuid)
        return if File.exists?(filepath)
        Fx18s::constructNewFile(objectuuid)
    end

    # Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        Fx18s::computeLocalFx18Filepath(objectuuid)
    end

    # --------------------------------------------------------------

    # Fx18s::setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setAttribute1(eventuuid, eventTime, objectuuid, attname, attvalue, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
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
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=? order by _eventTime_", ["attribute", attname]) do |row|
            attvalue = row["_eventData3_"]
        end
        db.close
        attvalue
    end

    # --------------------------------------------------------------

    # Fx18s::setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsAdd1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_, _eventData5_) values (?, ?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, "setops", "add", setuuid, itemuuid, JSON.generate(value)]
        db.close
    end

    # Fx18s::setsAdd2(objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsAdd2(objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
        Fx18s::setsAdd1(SecureRandom.uuid, Time.new.to_f, objectuuid, setuuid, itemuuid, value, shouldDownloadFileIfFoundOnRemoteDrive)
    end

    # Fx18s::setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsRemove1(eventuuid, eventTime, objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_, _eventData4_) values (?, ?, ?, ?, ?, ?)", [eventuuid, eventTime, "setops", "remove", setuuid, itemuuid]
        db.close
    end

    # Fx18s::setsRemove2(objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsRemove2(objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        Fx18s::setsRemove1(SecureRandom.uuid, Time.new.to_f, objectuuid, setuuid, itemuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    end

    # Fx18s::setsItems(objectuuid, setuuid, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.setsItems(objectuuid, setuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true

        # -----------------------------|
        # item = {"itemuuid", "value"} |
        # items = Array[item]          |
        # -----------------------------|

        items = []

        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData3_=? order by _eventTime_", ["setops", setuuid]) do |row|
            operation = row["_eventData2_"]
            if operation == "add" then
                itemuuid = row["_eventData4_"]
                value = JSON.parse(row["_eventData5_"])
                items = items.reject{|item| item["itemuuid"] == itemuuid } # remove any existing item with that itemuuid
                items << {"itemuuid" => itemuuid, "value" => value}        # performing the add operation
            end
            if operation == "remove" then
                itemuuid = row["_eventData4_"]
                items = items.reject{|item| item["itemuuid"] == itemuuid } # remove the item with that itemuuid
            end
        end
        db.close
        
        items.map{|item| item["value"]}
    end

    # --------------------------------------------------------------

    # Fx18s::putBlob1(eventuuid, eventTime, objectuuid, key, blob, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.putBlob1(eventuuid, eventTime, objectuuid, key, blob, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_eventuuid_, _eventTime_, _eventData1_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, "datablob", key, blob]
        db.close
    end

    # Fx18s::putBlob2(objectuuid, key, blob, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.putBlob2(objectuuid, key, blob, shouldDownloadFileIfFoundOnRemoteDrive)
        Fx18s::putBlob1(SecureRandom.uuid, Time.new.to_f, objectuuid, key, blob, shouldDownloadFileIfFoundOnRemoteDrive)
    end

    # Fx18s::putBlob3(objectuuid, blob, shouldDownloadFileIfFoundOnRemoteDrive) # nhash
    def self.putBlob3(objectuuid, blob, shouldDownloadFileIfFoundOnRemoteDrive)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        Fx18s::putBlob2(objectuuid, nhash, blob, shouldDownloadFileIfFoundOnRemoteDrive)
        nhash
    end

    # Fx18s::getBlobOrNull(objectuuid, key, shouldDownloadFileIfFoundOnRemoteDrive)
    def self.getBlobOrNull(objectuuid, key, shouldDownloadFileIfFoundOnRemoteDrive)
        filepath = Fx18s::acquireFilepathOrError(objectuuid, shouldDownloadFileIfFoundOnRemoteDrive)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        data = nil
        db.execute("select * from _fx18_ where _eventData1_=? and _eventData2_=?", ["datablob", key]) do |row|
            data = row["_eventData3_"]
        end
        db.close
        data
    end
end
