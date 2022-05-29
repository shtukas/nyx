# encoding: UTF-8

$InMemoryObjectsDB = nil
$InMemoryObjectsDeployedSnapshot = nil

class InMemoryObjects

    # InMemoryObjects::rebuildInMemoryDatabaseFromObjects(objects)
    def self.rebuildInMemoryDatabaseFromObjects(objects)
        $InMemoryObjectsDB = SQLite3::Database.new(":memory:")
        $InMemoryObjectsDB.results_as_hash = true
        $InMemoryObjectsDB.busy_timeout = 117
        $InMemoryObjectsDB.busy_handler { |count| true }
        $InMemoryObjectsDB.execute "CREATE TABLE _objects_ (_objectuuid_ text primary key, _mikuType_ text, _object_ text, _ordinal_ float, _universe_ text);"

        objects.each{|object|
            ordinal = object["ordinal"] || 0
            $InMemoryObjectsDB.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_, _universe_) values (?,?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal, object["universe"]]
        }
    end

    # ---------------------------------------------------
    # Reading

    # InMemoryObjects::objects()
    def self.objects()
        answer = []
        $InMemoryObjectsDB.execute("select * from _objects_ order by _ordinal_", []) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # InMemoryObjects::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        answer = []
        $InMemoryObjectsDB.execute("select * from _objects_ where _mikuType_=? order by _ordinal_", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # InMemoryObjects::getObjectsByMikuTypeAndUniverse(mikuType, universe)
    def self.getObjectsByMikuTypeAndUniverse(mikuType, universe)
        answer = []
        $InMemoryObjectsDB.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_", [mikuType, universe]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # InMemoryObjects::getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
    def self.getObjectsByMikuTypeAndUniverseByOrdinalLimit(mikuType, universe, n)
        answer = []
        $InMemoryObjectsDB.execute("select * from _objects_ where _mikuType_=? and _universe_=? order by _ordinal_ limit ?", [mikuType, universe, n]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        answer
    end

    # InMemoryObjects::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        answer = nil
        $InMemoryObjectsDB.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        answer
    end

    # ---------------------------------------------------
    # Writing

    # InMemoryObjects::commit(object)
    def self.commit(object)

        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?

        puts "We are not expecting to commit objects while a snapshot is deployed".yellow
        puts JSON.pretty_generate(object).yellow
        LucilleCore::pressEnterToContinue()
        puts "Exiting"
        exit
    end

    # InMemoryObjects::destroy(uuid)
    def self.destroy(uuid)
        puts "We are not expecting to destroy objects while a snapshot is deployed".yellow
        puts "uuid: #{uuid}"
        puts "Exiting".yellow
        exit
    end
end
