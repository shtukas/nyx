
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

    # SelectionLookupDatabaseIO::addRecord2(db, objecttype, objectuuid, fragment)
    def self.addRecord2(db, objecttype, objectuuid, fragment)
        db.execute "insert into lookup (_objecttype_, _objectuuid_, _fragment_) values ( ?, ?, ? )", [objecttype, objectuuid, fragment]
    end

    # SelectionLookupDatabaseIO::updateLookupForDatapoint(datapoint)
    def self.updateLookupForDatapoint(datapoint)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], NSDataPoint::toString(datapoint, false).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(node["uuid"])
        SelectionLookupDatabaseIO::addRecord("node", node["uuid"], node["uuid"])
        SelectionLookupDatabaseIO::addRecord("node", node["uuid"], NSDataPoint::toString(node, false).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForAsteroid(asteroid)
    def self.updateLookupForAsteroid(asteroid)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(asteroid["uuid"])
        SelectionLookupDatabaseIO::addRecord("asteroid", asteroid["uuid"], asteroid["uuid"])
        SelectionLookupDatabaseIO::addRecord("asteroid", asteroid["uuid"], Asteroids::toString(asteroid).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForWave(wave)
    def self.updateLookupForWave(wave)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], Waves::toString(wave).downcase)
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
    def reloadData()
        @databaseRecords = SelectionLookupDatabaseIO::getDatabaseRecords()
                                .map{ |record| 
                                    record["fragment"] = record["fragment"].downcase
                                    record
                                }
        @supermap = {} # Map[ pattern: String, records: Array[DatabaseRecord] ]
        @cachedObjects = {} # Map[ uuid: String, object: Object ]
    end

    def initialize()
        reloadData()
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

    def patternToDatapoints(pattern)
        patternToRecords(pattern)
            .map{|record| objectUUIDToObjectOrNull(record["objectuuid"]) }
            .compact
            .select{|object| GenericObjectInterface::isDataPoint(object) }
    end

    def patternToAsteroids(pattern)
        patternToRecords(pattern)
            .map{|record| objectUUIDToObjectOrNull(record["objectuuid"]) }
            .compact
            .select{|object| GenericObjectInterface::isAsteroid(object) }
    end

    def patternToWaves(pattern)
        patternToRecords(pattern)
            .map{|record| objectUUIDToObjectOrNull(record["objectuuid"]) }
            .compact
            .select{|object| object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" }
    end
end

$SelectionLookupDatabaseInMemoryA22379F6 = SelectionLookupDatabaseInMemory.new()

class SelectionLookupDataset

    # SelectionLookupDataset::updateLookupForDatapoint(datapoint)
    def self.updateLookupForDatapoint(datapoint)
        SelectionLookupDatabaseIO::updateLookupForDatapoint(datapoint)
        $SelectionLookupDatabaseInMemoryA22379F6.reloadData()
    end

    # SelectionLookupDataset::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        SelectionLookupDatabaseIO::updateLookupForNode(node)
        $SelectionLookupDatabaseInMemoryA22379F6.reloadData()
    end

    # SelectionLookupDataset::updateLookupForAsteroid(asteroid)
    def self.updateLookupForAsteroid(asteroid)
        SelectionLookupDatabaseIO::updateLookupForAsteroid(asteroid)
        $SelectionLookupDatabaseInMemoryA22379F6.reloadData()
    end

    # SelectionLookupDataset::rebuildDatapointsLookup(verbose)
    def self.rebuildDatapointsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["datapoint"]

        NSDataPoint::datapoints()
            .each{|datapoint|
                if verbose then
                    puts "datapoint: #{datapoint["uuid"]} , #{NSDataPoint::toString(datapoint, false)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], NSDataPoint::toString(datapoint, false))
            }

        db.close

        $SelectionLookupDatabaseInMemoryA22379F6.reloadData()
    end

    # SelectionLookupDataset::rebuildAsteroidsLookup(verbose)
    def self.rebuildAsteroidsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["asteroid"]

        Asteroids::asteroids()
            .each{|asteroid|
                if verbose then
                    puts "asteroid: #{asteroid["uuid"]} , #{Asteroids::toString(asteroid)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "asteroid", asteroid["uuid"], asteroid["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "asteroid", asteroid["uuid"], Asteroids::toString(asteroid))
            }

        db.close

        $SelectionLookupDatabaseInMemoryA22379F6.reloadData()
    end

    # SelectionLookupDataset::rebuildWavesLookup(verbose)
    def self.rebuildWavesLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["wave"]

        Waves::waves()
            .each{|wave|
                if verbose then
                    puts "wave: #{wave["uuid"]} , #{Waves::toString(wave)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "wave", wave["uuid"], wave["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "wave", wave["uuid"], Waves::toString(wave))
            }

        db.close

        $SelectionLookupDatabaseInMemoryA22379F6.reloadData()
    end

    # SelectionLookupDataset::rebuildDataset(verbose)
    def self.rebuildDataset(verbose)
        SelectionLookupDataset::rebuildDatapointsLookup(verbose)
        SelectionLookupDataset::rebuildAsteroidsLookup(verbose)
        SelectionLookupDataset::rebuildWavesLookup(verbose)
    end

    # SelectionLookupDataset::patternToDatapoints(pattern)
    def self.patternToDatapoints(pattern)
        $SelectionLookupDatabaseInMemoryA22379F6.patternToDatapoints(pattern)
    end

    # SelectionLookupDataset::patternToAsteroids(pattern)
    def self.patternToAsteroids(pattern)
        $SelectionLookupDatabaseInMemoryA22379F6.patternToAsteroids(pattern)
    end

    # SelectionLookupDataset::patternToWaves(pattern)
    def self.patternToWaves(pattern)
        $SelectionLookupDatabaseInMemoryA22379F6.patternToWaves(pattern)
    end
end
