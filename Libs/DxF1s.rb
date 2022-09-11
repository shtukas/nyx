
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

    # DxF1::putRow(row)
    def self.putRow(row)
        objectuuid = row["_objectuuid_"]
        eventuuid  = row["_eventuuid_"]
        eventTime  = row["_eventTime_"]
        eventType  = row["_eventType_"]
        attname    = row["_name_"]
        attvalue   = row["_value_"]

        raise "1aa8abf7-0075-4c98-8b43-20f5f43b03be" if eventType != "attribute"

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

        db = SQLite3::Database.new(DxF1::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, "attribute", attname, attvalue]
        db.close
    end

    # DxF1::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)
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

        filepath = DxF1::filepath(objectuuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, "attribute", attname, JSON.generate(attvalue)]
        db.close
    end

    # DxF1::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
        DxF1::setAttribute0NoEvents(objectuuid, eventuuid, eventTime, attname, attvalue)

        SystemEvents::broadcast({
            "mikuType"   => "AttributeUpdate",
            "objectuuid" => objectuuid,
            "eventuuid"  => eventuuid,
            "eventTime"  => eventTime,
            "attname"    => attname,
            "attvalue"   => attvalue
        })

        Mercury2::put("e0fba9fd-c00b-4d0c-b884-4f058ef87653", {
            "unixtime"   => Time.new.to_i,
            "objectuuid" => objectuuid
        })

        TheIndex::updateIndexAtObjectAttempt(objectuuid)
    end

    # DxF1::setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.setAttribute1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "DxF1::setAttribute1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        DxF1::setAttribute0(objectuuid, eventuuid, eventTime, attname, attvalue)
    end

    # DxF1::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        DxF1::setAttribute1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # DxF1::getAttributeAtFileOrNull(filepath, attname)
    def self.getAttributeAtFileOrNull(filepath, attname)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _dxf1_ where _name_=? order by _eventTime_", [attname]) do |row|
            attvalue = JSON.parse(row["_value_"])
        end
        db.close
        attvalue
    end

    # DxF1::getAttributeOrNull(objectuuid, attname)
    def self.getAttributeOrNull(objectuuid, attname)
        DxF1::getAttributeAtFileOrNull(DxF1::filepath(objectuuid), attname)
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
        value = DxF1::getAttributeOrNull(objectuuid, "isAlive")
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
        SystemEvents::process({
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

        #Mercury2::put("e0fba9fd-c00b-4d0c-b884-4f058ef87653", {
        #    "unixtime"   => Time.new.to_i,
        #    "objectuuid" => objectuuid
        #})
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

    # DxF1::records(filepath)
    def self.records(filepath)
        records = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _dxf1_ where _eventType_=?", ["attribute"]) do |row|
            records << row
        end
        db.close
        records
    end

    # DxF1::filepathIsDxF1(filepath)
    def self.filepathIsDxF1(filepath)
        CommonUtils::ends_with?(filepath, ".dxf1.sqlite3")
    end

    # DxF1::databankRepositoryDxF1sFilepathEnumerator()
    def self.databankRepositoryDxF1sFilepathEnumerator()
        Enumerator.new do |filepaths|
            Find.find(DxF1::pathToRepository()) do |path|
                next if !File.file?(path)
                next if !DxF1::filepathIsDxF1(path)
                filepaths << path
            end
        end
    end
end

class DxF1Elizabeth

    # XCacheDatablobs::putBlob(blob)
    # XCacheDatablobs::getBlobOrNull(nhash)

    def initialize(objectuuid)
        @objectuuid  = objectuuid
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

class DxF1Utils
    # DxF1Utils::itemIsAlive(item)
    def self.itemIsAlive(item)
        item["isAlive"].nil? or item["isAlive"]
    end
end

class DxF1OrbitalExpansion

    # DxF1::copyFileToDesktop(objectuuid)
    def self.copyFileToDesktop(objectuuid)
        filepath1 = DxF1::filepathIfExistsOrNullNoSideEffect(objectuuid)
        return if filepath1.nil?
        filepath2 = "#{ENV['HOME']}/Desktop/#{File.basename(filepath1)}"
        FileUtils.cp(filepath1, filepath2)
        DxF1::renameDxF1FileAsUserFriendly(filepath2)
    end

    # DxF1::renameDxF1FileAsUserFriendly(filepath)
    def self.renameDxF1FileAsUserFriendly(filepath)
        # We can only rename on the Desktop on within Orbital
        if !filepath.include?("#{ENV['HOME']}/Desktop") or !filepath.include?(Config::orbital()) then
            raise "(error: 7b7810ea-d608-4d1b-9076-9f536db6e6aa) You cannot do that with filepath: #{filepath}"
        end
        if !DxF1::filepathIsDxF1(filepath) then
            raise "(error: d5f2a487-deca-4a1a-94eb-db12968fcf1e) You cannot do that with filepath: #{filepath}"
        end
        item = DxF1::getProtoItemAtFilepathOrNull(filepath)
        return if item.nil?
        genericDescription = PolyFunctions::genericDescription(item)
        filenamePrefix = CommonUtils::sanitiseStringForFilenaming(genericDescription)
        filename2 = "#{filenamePrefix} [#{item["mikuType"]}].dxf1.sqlite3"
        filepath2 = "#{File.dirname(filepath)}/#{filename2}"
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # DxF1OrbitalExpansion::orbitalDxF1FilepathEnumerator()
    def self.orbitalDxF1FilepathEnumerator()
        Enumerator.new do |filepaths|
            Find.find(Config::orbital()) do |path|
                next if !File.file?(path)
                next if !DxF1::filepathIsDxF1(path)
                next if path.include?(DxF1::pathToRepository())
                filepaths << path
            end
        end
    end

    # DxF1OrbitalExpansion::exposeFileContents(filepath)
    def self.exposeFileContents(filepath)
        if !filepath.include?(Config::orbital()) then
            raise "(error: bf72c1c7-5fb5-453e-9710-9e691ca97219) You need to point at orbital. Given fiepath: #{filepath}"
        end
        if !DxF1::filepathIsDxF1(filepath) then
            raise "(error: d5f2a487-deca-4a1a-94eb-db12968fcf1e) You cannot do that with filepath: #{filepath}"
        end
        item = DxF1::getProtoItemAtFilepathOrNull(filepath)
        return if item.nil?

        if item["mikuType"] == "NxPerson" then
            return
        end

        raise "(error: 5689a74c-813a-4459-9bfc-565458372eff) I don't know how to expose MikuType #{item["mikuType"]}"
    end

    # DxF1OrbitalExpansion::exposeAllExported()
    def self.exposeAllExported()
        DxF1OrbitalExpansion::orbitalDxF1FilepathEnumerator().each{|filepath|
            puts filepath
            DxF1OrbitalExpansion::exposeFileContents(filepath)
        }
    end
end

class DxF1sAtStargateCentral

    # DxF1sAtStargateCentral::dxF1Filepath(objectuuid)
    def self.dxF1Filepath(objectuuid)
        StargateCentral::ensureCentral()
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        folderpath = "#{StargateCentral::pathToCentral()}/DxF1s/#{sha1[0, 2]}"
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

    # DxF1sAtStargateCentral::localToCentralFilePropagation(filepath1, filepath2)
    def self.localToCentralFilePropagation(filepath1, filepath2)

        puts "DxF1sAtStargateCentral::localToCentralFilePropagation(filepath1, filepath2)"
        puts "    - #{filepath1}"
        puts "    - #{filepath2}"

        db1 = SQLite3::Database.new(filepath1)
        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true

        db2 = SQLite3::Database.new(filepath2)
        db2.busy_timeout = 117
        db2.busy_handler { |count| true }
        db2.results_as_hash = true

        remoteEventuuids = []

        db2.execute("select _eventuuid_ from _dxf1_", []) do |row|
            remoteEventuuids << row["_eventuuid_"]
        end

        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db1.execute("select * from _dxf1_ order by _eventTime_", []) do |row|

            # create table _dxf1_ (_objectuuid_ text, _eventuuid_ text primary key, _eventTime_ float, _eventType_ text, _name_ text, _value_ blob);

            objectuuid = row["_objectuuid_"]
            eventuuid  = row["_eventuuid_"]
            eventTime  = row["_eventTime_"]
            eventType  = row["_eventType_"]
            attname    = row["_name_"]
            attvalue   = row["_value_"]

            if objectuuid.nil? then
                raise "(error: 5f8d7d27-d85d-44f6-a009-66c455662b70)"
            end
            if eventuuid.nil? then
                raise "(error: c7f1e621-ca91-4aec-93eb-69696255f5c3)"
            end
            if eventTime.nil? then
                raise "(error: 66d59d04-7588-4fb8-af01-e13500bba102)"
            end
            if attname.nil? then
                raise "(error: 3eb066bd-6881-4efa-a1f7-326ea51701b5)"
            end
            if attvalue.nil? then
                raise "(error: b4917158-4902-47d3-979c-4587bb195ee3)"
            end

            next if remoteEventuuids.include?(eventuuid)

            puts "    insert eventuuid: #{eventuuid} @ #{filepath2}"

            # db2.execute "delete from _dxf1_ where _eventuuid_=?", [eventuuid] # We do not need to delete if we did the `remoteEventuuids.include?` check
            db2.execute "insert into _dxf1_ (_objectuuid_, _eventuuid_, _eventTime_, _eventType_, _name_, _value_) values (?, ?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventType, attname, attvalue]

        end

        db2.close

        # By now all the events have been propagated.
        # We are now going to delete the datablobs on local and vacuum the file if needed

        hasDatablobs = false
        db1.execute("select count(*) as _count_ from _dxf1_ where _eventType_=?", ["datablob"]) do |row|
            count = row["_count_"]
            hasDatablobs = (count > 0)
        end
        
        if hasDatablobs then
            puts "    removing datablobs from #{filepath1}"
            db1.execute "delete from _dxf1_ where _eventType_=?", ["datablob"]
            db1.execute "vacuum", []
        end

        db1.close
    end

    # DxF1sAtStargateCentral::getDatablobOrNull(objectuuid, nhash)
    def self.getDatablobOrNull(objectuuid, nhash)
        db = SQLite3::Database.new(DxF1sAtStargateCentral::dxF1Filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _dxf1_ where _name_=? order by _eventTime_", [nhash]) do |row|
            blob = row["_value_"]
        end
        db.close
        blob
    end
end
