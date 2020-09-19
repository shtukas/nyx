
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
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], NSNode1638::toString(datapoint, false).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(node["uuid"])
        SelectionLookupDatabaseIO::addRecord("node", node["uuid"], node["uuid"])
        SelectionLookupDatabaseIO::addRecord("node", node["uuid"], NSNode1638::toString(node, false).downcase)
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
    # DatabaseRecord: [objecttype: string, objectuuid: String, fragment: String]
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

class SelectionLookupDataset

    # SelectionLookupDataset::updateLookupForDatapoint(datapoint)
    def self.updateLookupForDatapoint(datapoint)
        SelectionLookupDatabaseIO::updateLookupForDatapoint(datapoint)
    end

    # SelectionLookupDataset::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        SelectionLookupDatabaseIO::updateLookupForNode(node)
    end

    # SelectionLookupDataset::updateLookupForAsteroid(asteroid)
    def self.updateLookupForAsteroid(asteroid)
        SelectionLookupDatabaseIO::updateLookupForAsteroid(asteroid)
    end

    # SelectionLookupDataset::rebuildDatapointsLookup(verbose)
    def self.rebuildDatapointsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["datapoint"]

        NSNode1638::datapoints()
            .each{|datapoint|
                if verbose then
                    puts "datapoint: #{datapoint["uuid"]} , #{NSNode1638::toString(datapoint, false)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], NSNode1638::toString(datapoint, false))
                if datapoint["type"] == "NyxFile" then
                    SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["name"])
                end
                if datapoint["type"] == "NyxDirectory" then
                    SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["name"])
                end
            }

        db.close
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
    end

    # SelectionLookupDataset::rebuildDataset(verbose)
    def self.rebuildDataset(verbose)
        SelectionLookupDataset::rebuildDatapointsLookup(verbose)
        SelectionLookupDataset::rebuildAsteroidsLookup(verbose)
        SelectionLookupDataset::rebuildWavesLookup(verbose)
    end

    # SelectionLookupDataset::patternToDatapoints(pattern)
    def self.patternToDatapoints(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "datapoint" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToAsteroids(pattern)
    def self.patternToAsteroids(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "asteroid" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToWaves(pattern)
    def self.patternToWaves(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "wave" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end
end
