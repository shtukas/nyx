
# encoding: UTF-8

class SelectionLookupDatabaseIO

    # SelectionLookupDatabaseIO::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Selection-Lookup-Database.sqlite3"
    end

    # SelectionLookupDatabaseIO::removeRecordsAgainstObject(objectuuid)
    def self.removeRecordsAgainstObject(objectuuid)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # SelectionLookupDatabaseIO::addRecord(objecttype, objectuuid, fragment)
    def self.addRecord(objecttype, objectuuid, fragment)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "insert into lookup (_objecttype_, _objectuuid_, _fragment_) values ( ?, ?, ? )", [objecttype, objectuuid, fragment]
        db.close
    end

    # SelectionLookupDatabaseIO::addRecord2(db, objecttype, objectuuid, fragment)
    def self.addRecord2(db, objecttype, objectuuid, fragment)
        db.execute "insert into lookup (_objecttype_, _objectuuid_, _fragment_) values ( ?, ?, ? )", [objecttype, objectuuid, fragment]
    end

    # SelectionLookupDatabaseIO::getDatabaseRecords(): Array[DatabaseRecord]
    # DatabaseRecord: [objecttype: string, objectuuid: String, fragment: String]
    def self.getDatabaseRecords()
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
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

    # ---------------------------------------------------------

    # SelectionLookupDataset::updateLookupForNGX15(datapoint)
    def self.updateLookupForNGX15(datapoint)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], NGX15::toString(datapoint))
    end

    # SelectionLookupDataset::updateLookupForQuark(quark)
    def self.updateLookupForQuark(quark)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(quark["uuid"])
        SelectionLookupDatabaseIO::addRecord("quark", quark["uuid"], quark["uuid"])
        SelectionLookupDatabaseIO::addRecord("quark", quark["uuid"], Quarks::toString(quark))
    end

    # SelectionLookupDataset::updateLookupForNavigationNode(node)
    def self.updateLookupForNavigationNode(node)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(node["uuid"])
        SelectionLookupDatabaseIO::addRecord("navigation-node", node["uuid"], node["uuid"])
        SelectionLookupDatabaseIO::addRecord("navigation-node", node["uuid"], NavigationNodes::toString(node))
    end

    # SelectionLookupDataset::updateLookupForWave(wave)
    def self.updateLookupForWave(wave)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], Waves::toString(wave))
    end

    # ---------------------------------------------------------

    # SelectionLookupDataset::rebuildNGX15sLookup(verbose)
    def self.rebuildNGX15sLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from lookup where _objecttype_=?", ["ngx15"]

        NGX15::ngx15s()
            .each{|ngx15|
                if verbose then
                    puts "ngx15: #{ngx15["uuid"]} , #{NGX15::toString(ngx15)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "ngx15", ngx15["uuid"], ngx15["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "ngx15", ngx15["uuid"], NGX15::toString(ngx15))
                if ngx15["type"] == "NGX15" then
                    SelectionLookupDatabaseIO::addRecord2(db, "ngx15", ngx15["uuid"], ngx15["ngx15"])
                end
            }

        db.close
    end

    # SelectionLookupDataset::rebuildQuarksLookup(verbose)
    def self.rebuildQuarksLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from lookup where _objecttype_=?", ["quark"]

        Quarks::quarks()
            .each{|quark|
                if verbose then
                    puts "quark: #{quark["uuid"]} , #{Quarks::toString(quark)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "quark", quark["uuid"], quark["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "quark", quark["uuid"], Quarks::toString(quark))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildNavigationNodesLookup(verbose)
    def self.rebuildNavigationNodesLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from lookup where _objecttype_=?", ["navigation-node"]

        NavigationNodes::nodes()
            .each{|node|
                if verbose then
                    puts "navigation node: #{node["uuid"]} , #{NavigationNodes::toString(node)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "navigation-node", node["uuid"], node["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "navigation-node", node["uuid"], NavigationNodes::toString(node))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildWavesLookup(verbose)
    def self.rebuildWavesLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
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
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from lookup", []
        db.close

        SelectionLookupDataset::rebuildNGX15sLookup(verbose)
        SelectionLookupDataset::rebuildQuarksLookup(verbose)
        SelectionLookupDataset::rebuildNavigationNodesLookup(verbose)
        SelectionLookupDataset::rebuildWavesLookup(verbose)
    end

    # ---------------------------------------------------------

    # SelectionLookupDataset::patternToRecords(pattern)
    def self.patternToRecords(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
        #{
        #    "objecttype"
        #    "objectuuid"
        #    "fragment"
        #}
    end
end
