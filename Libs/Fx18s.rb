
class Fx256

    # Fx256::filepath(objectuuid)
    def self.filepath(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256/#{sha1[0, 1]}/#{sha1[1, 1]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/Fx18.sqlite3"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table _fx18_ (_objectuuid_ text, _eventuuid_ text primary key, _eventTime_ float, _eventData2_ blob, _eventData3_ blob)", [])
            db.close
        end
        filepath
    end

    # Fx256::filepathAtCoordinates(name1, name2)
    def self.filepathAtCoordinates(name1, name2)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256/#{name1}/#{name2}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/Fx18.sqlite3"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table _fx18_ (_objectuuid_ text, _eventuuid_ text primary key, _eventTime_ float, _eventData2_ blob, _eventData3_ blob)", [])
            db.close
        end
        filepath
    end

    # Fx256::commit(objectuuid, eventuuid, eventTime, eventData2, eventData3) # row or null
    def self.commit(objectuuid, eventuuid, eventTime, eventData2, eventData3) 
        if objectuuid.nil? then
            raise "(error: a3202192-2d16-4f82-80e9-a86a18d407c8)"
        end
        if eventuuid.nil? then
            raise "(error: 1025633f-b0aa-42ed-9751-b5f87af23450)"
        end
        if eventTime.nil? then
            raise "(error: 9a6caf6b-fa31-4fda-b963-f0c04f4e50a2)"
        end
        if eventData2.nil? then
            raise "(error: 0b103332-556d-4043-9cdd-81cf70b7a289)"
        end
        if eventData3.nil? then
            raise "(error: db06a417-68d1-471d-888f-9e497b268750)"
        end

        db = SQLite3::Database.new(Fx256::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _fx18_ where _eventuuid_=?", [eventuuid]
        db.execute "insert into _fx18_ (_objectuuid_, _eventuuid_, _eventTime_, _eventData2_, _eventData3_) values (?, ?, ?, ?, ?)", [objectuuid, eventuuid, eventTime, eventData2, eventData3]
        returnedrow = nil
        db.execute("select * from _fx18_ where _eventuuid_=?", [eventuuid]) do |row|
            returnedrow = row.clone
        end
        db.close
        Fx256X::flashCacheBranchAtObjectuuid(objectuuid)
        returnedrow
    end 

    # Fx256::commitRow(row)
    def self.commitRow(row)
        Fx256::commit(row["_objectuuid_"], row["_eventuuid_"], row["_eventTime_"], row["_eventData2_"], row["_eventData3_"])
    end

    # Fx256::getProtoItemOrNull(objectuuid)
    def self.getProtoItemOrNull(objectuuid)
        item = {}
        db = SQLite3::Database.new(Fx256::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objectuuids = []
        db.execute("select * from _fx18_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            attrname = row["_eventData2_"]
            attvalue = 
                begin
                    JSON.parse(row["_eventData3_"])
                rescue 
                    row["_eventData3_"] # We have some non json encoded legacy data at that attribute
                end
            item[attrname] = attvalue
        end
        db.close
        if item["uuid"].nil? then
            return nil
        end
        item
    end

    # Fx256::objectIsAlive(objectuuid)
    def self.objectIsAlive(objectuuid)
        value = Fx18Attributes::getJsonDecodeOrNull(objectuuid, "isAlive")
        return true if value.nil?
        value
    end

    # Fx256::getAliveProtoItemOrNull(objectuuid)
    def self.getAliveProtoItemOrNull(objectuuid)
        item = Fx256::getProtoItemOrNull(objectuuid)
        return nil if item.nil?
        return nil if (!item["isAlive"].nil? and !item["isAlive"]) # Object is logically deleted
        item
    end

    # Fx256::objectrows(objectuuid)
    def self.objectrows(objectuuid)
        db = SQLite3::Database.new(Fx256::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        rows = []
        db.execute("select * from _fx18_ where _objectuuid_=? order by _eventTime_", [objectuuid]) do |row|
            rows << row.clone
        end
        db.close
        rows
    end

    # Fx256::broadcastObjectEvents(objectuuid)
    def self.broadcastObjectEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType" => "Fx18-records",
            "records"  => Fx256::objectrows(objectuuid)
        })
    end

    # Fx256::level1Foldernames()
    def self.level1Foldernames()
        ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    end

    # Fx256::level2Foldernames()
    def self.level2Foldernames()
        ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    end

    # Fx256::eventuuids()
    def self.eventuuids()
        eventuuids = []
        Fx256::level1Foldernames().each{|name1|
            Fx256::level2Foldernames().each{|name2|
                db = SQLite3::Database.new(Fx256::filepathAtCoordinates(name1, name2))
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select _eventuuid_ from _fx18_ order by _eventTime_", []) do |row|
                    eventuuids << row["_eventuuid_"]
                end
                db.close
            }
        }
        eventuuids
    end

    # Fx256::objectuuidsAtLevel2(name1, name2)
    def self.objectuuidsAtLevel2(name1, name2)
        objectuuids = []
        db = SQLite3::Database.new(Fx256::filepathAtCoordinates(name1, name2))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select distinct(_objectuuid_) as _objectuuid_ from _fx18_", []) do |row|
            objectuuids << row["_objectuuid_"]
        end
        db.close
        objectuuids
    end

    # Fx256::objectuuids()
    def self.objectuuids()
        objectuuids = []
        Fx256::level1Foldernames().each{|name1|
            Fx256::level2Foldernames().each{|name2|
                objectuuids = objectuuids + Fx256::objectuuidsAtLevel2(name1, name2)
            }
        }
        objectuuids
    end

    # Fx256::rows()
    def self.rows()
        rows = []
        Fx256::level1Foldernames().each{|name1|
            Fx256::level2Foldernames().each{|name2|
                db = SQLite3::Database.new(Fx256::filepathAtCoordinates(name1, name2))
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _fx18_ order by _eventTime_", []) do |row|
                    rows << row.clone
                end
                db.close
            }
        }
        rows
    end

    # Fx256::deleteObjectLogicallyNoEvents(objectuuid)
    def self.deleteObjectLogicallyNoEvents(objectuuid)
        Fx18Attributes::setJsonEncoded(objectuuid, "isAlive", false)
    end

    # Fx256::deleteObjectLogically(objectuuid)
    def self.deleteObjectLogically(objectuuid)
        Fx256::deleteObjectLogicallyNoEvents(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "NxDeleted",
            "objectuuid" => objectuuid,
        })
        SystemEvents::processEvent({
            "mikuType"   => "(object has been logically deleted)",
            "objectuuid" => objectuuid,
        })
    end

    # Fx256::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "Fx18-records" then
            event["records"].each{|row|
                Fx256::commitRow(row)
            }
        end
    end

    # Fx256::edit(item) # item
    def self.edit(item) # item
        if item["mikuType"] == "TopLevel" then
            uuid = item["uuid"]
            text = item["text"]
            text = CommonUtils::editTextSynchronously(text)
            Fx18Attributes::setJsonEncoded(uuid, "text", text)
            return Fx256::getProtoItemOrNull(uuid)
        end

        if item["nx111"] then
            puts "You are trying to edit a nx111 carrier"
            puts "Follow: 9e0705fc-8637-47f9-9bce-29df79d05292"
            exit
            return Fx256::getProtoItemOrNull(uuid)
        end

        raise "(error: 402f0ee5-4bd1-4b73-a418-d16ac12760ca)"
    end
end

class Fx18Attributes

    # Fx18Attributes::set1(objectuuid, eventuuid, eventTime, attname, attvalue)
    def self.set1(objectuuid, eventuuid, eventTime, attname, attvalue)
        puts "Fx18Attributes::set1(#{objectuuid}, #{eventuuid}, #{eventTime}, #{attname}, #{attvalue})"
        row = Fx256::commit(objectuuid, eventuuid, eventTime, attname, JSON.generate(attvalue))
        if row then
            SystemEvents::broadcast({
                "mikuType" => "Fx18-records",
                "records"  => [row]
            })
        end
    end

    # Fx18Attributes::setJsonEncoded(objectuuid, attname, attvalue)
    def self.setJsonEncoded(objectuuid, attname, attvalue)
        Fx18Attributes::set1(objectuuid, SecureRandom.uuid, Time.new.to_f, attname, attvalue)
    end

    # Fx18Attributes::getJsonDecodeOrNull(objectuuid, attname)
    def self.getJsonDecodeOrNull(objectuuid, attname)
        db = SQLite3::Database.new(Fx256::filepath(objectuuid))
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _objectuuid_=? and _eventData2_=? order by _eventTime_", [objectuuid, attname]) do |row|
            attvalue = JSON.parse(row["_eventData3_"])
        end
        db.close
        attvalue
    end

    # Fx18Attributes::getJsonDecodeOrNullUsingFilepath(filepath, attname)
    def self.getJsonDecodeOrNullUsingFilepath(filepath, attname)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        attvalue = nil
        # It is of crutial importance that we `order by _eventTime_` to return the current (latest) value
        db.execute("select * from _fx18_ where _eventData2_=? order by _eventTime_", [attname]) do |row|
            attvalue = JSON.parse(row["_eventData3_"])
        end
        db.close
        attvalue
    end
end

class Fx256AtLevel2WithCache

    # Fx256AtLevel2WithCache::objectuuids(name1, name2)
    def self.objectuuids(name1, name2)
        #puts "Fx256AtLevel2WithCache::objectuuids(#{name1}, #{name2})"

        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-objectuuids.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::objectuuidsAtLevel2(name1, name2)

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2)
    def self.mikuTypeToObjectuuids(mikuType, name1, name2)
        #puts "Fx256AtLevel2WithCache::mikuTypeToObjectuuids(#{mikuType}, #{name1}, #{name2})"

        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-mikuTypeToObjectuuids-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256AtLevel2WithCache::objectuuids(name1, name2)
                        .select{|objectuuid| Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") == mikuType }

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel2WithCache::mikuTypeCount(mikuType, name1, name2)
    def self.mikuTypeCount(mikuType, name1, name2)
        #puts "Fx256AtLevel2WithCache::mikuTypeCount(#{mikuType}, #{name1}, #{name2})"
        Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2).size
    end

    # Fx256AtLevel2WithCache::mikuTypeToItems(mikuType, name1, name2)
    def self.mikuTypeToItems(mikuType, name1, name2)
        #puts "Fx256AtLevel2WithCache::mikuTypeToItems(#{mikuType}, #{name1}, #{name2})"
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-mikuTypeToItems-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        items = Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2)
                .map{|objectuuid| Fx256::getAliveProtoItemOrNull(objectuuid) }
                .compact

        Fx256X::fileput(cache, JSON.pretty_generate(items))
        items
    end

    # Fx256AtLevel2WithCache::nx20s(name1, name2)
    def self.nx20s(name1, name2)
        #puts "Fx256AtLevel2WithCache::nx20s(#{name1}, #{name2})"
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}/cache-nx20s.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        nx20s = Fx256AtLevel2WithCache::objectuuids(name1, name2)
                    .map {|objectuuid|
                        item = Fx256::getAliveProtoItemOrNull(objectuuid)
                        if item then
                            description = LxFunction::function("generic-description", item)
                            {
                                "announce"   => "(#{item["mikuType"]}) #{description}",
                                "unixtime"   => item["unixtime"],
                                "objectuuid" => item["uuid"]
                            }
                        else
                            nil
                        end
                    }
                    .compact

        Fx256X::fileput(cache, JSON.pretty_generate(nx20s))
        nx20s
    end

    # Fx256AtLevel2WithCache::flushCache(name1, name2)
    def self.flushCache(name1, name2)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/#{name2}"
        return if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath).start_with?("cache-") }
            .each{|filepath| FileUtils.rm(filepath) }
    end
end

class Fx256AtLevel1WithCache

    # Fx256AtLevel1WithCache::objectuuids(name1)
    def self.objectuuids(name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-objectuuids.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level2Foldernames()
                        .map{|name2| Fx256AtLevel2WithCache::objectuuids(name1, name2)}
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel1WithCache::mikuTypeToObjectuuids(mikuType, name1)
    def self.mikuTypeToObjectuuids(mikuType, name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-mikuTypeToObjectuuids-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level2Foldernames()
                        .map{|name2| Fx256AtLevel2WithCache::mikuTypeToObjectuuids(mikuType, name1, name2)}
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256AtLevel1WithCache::mikuTypeCount(mikuType, name1)
    def self.mikuTypeCount(mikuType, name1)
        Fx256AtLevel1WithCache::mikuTypeToObjectuuids(mikuType, name1).size
    end

    # Fx256AtLevel1WithCache::mikuTypeToItems(mikuType, name1)
    def self.mikuTypeToItems(mikuType, name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-mikuTypeToItems-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        items = Fx256::level2Foldernames()
                    .map{|name2| Fx256AtLevel2WithCache::mikuTypeToItems(mikuType, name1, name2)}
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(items))
        items
    end

    # Fx256AtLevel1WithCache::nx20s(name1)
    def self.nx20s(name1)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}/cache-nx20s.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        nx20s =  Fx256::level2Foldernames()
                    .map{|name2| Fx256AtLevel2WithCache::nx20s(name1, name2)}
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(nx20s))
        nx20s
    end

    # Fx256AtLevel1WithCache::flushCache(name1)
    def self.flushCache(name1)
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/#{name1}"
        return if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath).start_with?("cache-") }
            .each{|filepath| FileUtils.rm(filepath) }
    end
end

class Fx256WithCache

    # Fx256WithCache::objectuuids()
    def self.objectuuids()
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-objectuuids.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level1Foldernames()
                        .map{|name1| Fx256AtLevel1WithCache::objectuuids(name1) }
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256WithCache::mikuTypeToObjectuuids(mikuType)
    def self.mikuTypeToObjectuuids(mikuType)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-mikuTypeToObjectuuids-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        objectuuids = Fx256::level1Foldernames()
                        .map{|name1| Fx256AtLevel1WithCache::mikuTypeToObjectuuids(mikuType, name1) }
                        .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(objectuuids))
        objectuuids
    end

    # Fx256WithCache::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        Fx256WithCache::mikuTypeToObjectuuids(mikuType).size
    end

    # Fx256WithCache::mikuTypeToItems(mikuType)
    def self.mikuTypeToItems(mikuType)
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-mikuTypeToItems-#{mikuType}.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        items = Fx256::level1Foldernames()
                    .map{|name1| Fx256AtLevel1WithCache::mikuTypeToItems(mikuType, name1) }
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(items))
        items
    end

    # Fx256WithCache::nx20s()
    def self.nx20s()
        cache = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache/cache-nx20s.json"
        if File.exists?(cache) then
            return JSON.parse(IO.read(cache))
        end

        nx20s =  Fx256::level1Foldernames()
                    .map{|name1| Fx256AtLevel1WithCache::nx20s(name1) }
                    .flatten

        Fx256X::fileput(cache, JSON.pretty_generate(nx20s))
        nx20s
    end

    # Fx256AtLevel1WithCache::flushCache()
    def self.flushCache()
        folderpath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/Fx256-Cache"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| File.basename(filepath).start_with?("cache-") }
            .each{|filepath| FileUtils.rm(filepath) }
    end
end

class Fx256X

    # Fx256X::fileput(filepath, content)
    def self.fileput(filepath, content)
        parent = File.dirname(filepath)
        if !File.exists?(parent) then
            FileUtils.mkpath(parent)
        end
        File.open(filepath, "w") {|f| f.write(content) }
    end

    # Fx256X::flushCacheBranch(name1, name2)
    def self.flushCacheBranch(name1, name2)
        Fx256AtLevel2WithCache::flushCache(name1, name2)
        Fx256AtLevel1WithCache::flushCache(name1)
        Fx256WithCache::flushCache()
    end

    # Fx256X::flashCacheBranchAtObjectuuid(objectuuid)
    def self.flashCacheBranchAtObjectuuid(objectuuid)
        sha1 = Digest::SHA1.hexdigest(objectuuid)
        name1 = sha1[0, 1]
        name2 = sha1[1, 1]
        Fx256X::flushCacheBranch(name1, name2)
    end
end

class Fx18sSynchronisation

    # Fx18sSynchronisation::sync()
    def self.sync()

        DxPureFileManagement::bufferOutFilepathsEnumerator().each{|dxBufferOutFilepath|
            sha1 = File.basename(dxBufferOutFilepath).gsub(".sqlite3", "")
            eGridFilepath = DxPureFileManagement::energyGridDriveFilepath(sha1)
            if File.exists?(eGridFilepath) then
                eGridSha1 = Digest::SHA1.file(eGridFilepath).hexdigest
                if File.basename(eGridFilepath) != "#{eGridSha1}.sqlite3" then
                puts "Fx18sSynchronisation::sync()"
                    puts "    I am trying to move #{dxBufferOutFilepath}"
                    puts "    I found #{eGridFilepath}"
                    puts "    #{eGridFilepath} has a sha1 of #{eGridSha1}"
                    puts "    Which is an irregularity 🤔"
                    puts "    Exit"
                    exit
                end
            else
                puts "Fx18sSynchronisation::sync() copy"
                puts "    #{dxBufferOutFilepath}"
                puts "    #{eGridFilepath}"
                FileUtils.cp(dxBufferOutFilepath, eGridFilepath)
            end
            xcacheFilepath = DxPureFileManagement::xcacheFilepath(sha1)
            if !File.exists?(xcacheFilepath) then
                puts "Fx18sSynchronisation::sync() copy"
                puts "    #{dxBufferOutFilepath}"
                puts "    #{xcacheFilepath}"
                FileUtils.cp(dxBufferOutFilepath, xcacheFilepath)
            end
            puts "Fx18sSynchronisation::sync() deleting"
            puts "    #{dxBufferOutFilepath}"
            FileUtils.rm(dxBufferOutFilepath)
        }
    end
end
