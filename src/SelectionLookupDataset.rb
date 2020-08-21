
# encoding: UTF-8

class SelectionLookupDatabaseIO

    # SelectionLookupDatabaseIO::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Selection-Lookup-Database.sqlite3"
    end

    # SelectionLookupDatabaseIO::removeRecordsAgainstObject(objectuuid)
    def self.removeRecordsAgainstObject(objectuuid)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # SelectionLookupDatabaseIO::addRecord(objecttype, objectuuid, fragment)
    def self.addRecord(objecttype, objectuuid, fragment)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "insert into lookup (_objecttype_, _objectuuid_, _fragment_) values ( ?, ?, ? )", [objecttype, objectuuid, fragment]
        db.close
    end

    # SelectionLookupDatabaseIO::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(node["uuid"])
        SelectionLookupDatabaseIO::addRecord("node", node["uuid"], node["uuid"])
        SelectionLookupDatabaseIO::addRecord("node", node["uuid"], NSDataType1::toString(node))
    end

    # SelectionLookupDatabaseIO::updateLookupForDataline(dataline)
    def self.updateLookupForDataline(dataline)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(dataline["uuid"])
        SelectionLookupDatabaseIO::addRecord("dataline", dataline["uuid"], dataline["uuid"])
        SelectionLookupDatabaseIO::addRecord("dataline", dataline["uuid"], NSDataLine::toString(dataline))
    end

    # SelectionLookupDatabaseIO::getDatabaseRecords(): Array[DatabaseRecord]
    # DatabaseRecord: [objectuuid: String, fragment: String]
    def self.getDatabaseRecords()
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from lookup" , [] ) do |row|
            answer << {
                "objecttype" => row['_objecttype_'],
                "objectuuid" => row['_objectuuid_'],
                "fragment"   => row['_fragment_'],
            }
        end
        db.close
        answer
    end
end

class SelectionLookupDatabaseInMemory
    def initialize()
        @databaseRecords = SelectionLookupDatabaseIO::getDatabaseRecords()
                                .map{ |record| 
                                    record["fragment"] = record["fragment"].downcase
                                    record
                                }
        @supermap = {} # Map[ pattern: String, records: Array[DatabaseRecord] ]
        @cachedObjects = {} # Map[ uuid: String, object: Object ]
    end

    def patternAndRecordsToRecords(pattern, records)
        pattern = pattern.downcase
        @databaseRecords.select{|record| record["fragment"].include?(pattern) }
    end

    def patternToRecords(pattern)
        if @supermap[pattern] then
            return @supermap[pattern]
        end

        minipattern = pattern[0, pattern.size-1]
        if @supermap[minipattern] then
            records = patternAndRecordsToRecords(pattern, @supermap[minipattern])
            @supermap[pattern] = records
            return records
        end

        records = patternAndRecordsToRecords(pattern, @databaseRecords)
        @supermap[pattern] = records
        records
    end

    def objectUUIDToObjectOrNull(objectuuid)
        if @cachedObjects[objectuuid] then
            return @cachedObjects[objectuuid]
        end
        object = NyxObjects2::getOrNull(objectuuid)
        return nil if object.nil?
        @cachedObjects[objectuuid] = object
        object
    end

    def patternToNodes(pattern)
        patternToRecords(pattern)
            .map{|record| objectUUIDToObjectOrNull(record["objectuuid"]) }
            .compact
            .select{|object| GenericObjectInterface::isNode(object) }
    end

    def patternToDatalines(pattern)
        patternToRecords(pattern)
            .map{|record| objectUUIDToObjectOrNull(record["objectuuid"]) }
            .compact
            .select{|object| GenericObjectInterface::isDataline(object) }
    end
end

$SelectionLookupDatabaseInMemoryA22379F6 = SelectionLookupDatabaseInMemory.new()

class SelectionLookupDataset

    # SelectionLookupDataset::rebuildNodeLookup()
    def self.rebuildNodeLookup()
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["node"]
        db.close

        NSDataType1::objects()
            .each{|node|
                puts "node: #{node["uuid"]}"
                SelectionLookupDatabaseIO::updateLookupForNode(node)
            }
    end

    # SelectionLookupDataset::rebuildDalalineLookup()
    def self.rebuildDalalineLookup()
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["dataline"]
        db.close

        NSDataLine::datalines()
            .each{|dataline|
                puts "dataline: #{dataline["uuid"]}"
                SelectionLookupDatabaseIO::updateLookupForDataline(dataline)
            }
    end

    # SelectionLookupDataset::rebuildDataset()
    def self.rebuildDataset()
        SelectionLookupDataset::rebuildNodeLookup()
        SelectionLookupDataset::rebuildDalalineLookup()
    end

    # SelectionLookupDataset::patternToNodes(pattern)
    def self.patternToNodes(pattern)
        $SelectionLookupDatabaseInMemoryA22379F6.patternToNodes(pattern)
    end

    # SelectionLookupDataset::patternToDatalines(pattern)
    def self.patternToDatalines(pattern)
        $SelectionLookupDatabaseInMemoryA22379F6.patternToDatalines(pattern)
    end
end
