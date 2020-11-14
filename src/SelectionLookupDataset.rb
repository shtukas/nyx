
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

    # ---------------------------------------------------------

    # SelectionLookupDataset::updateLookupForNGX15(datapoint)
    def self.updateLookupForNGX15(datapoint)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], NGX15::toString(datapoint).downcase)
    end

    # SelectionLookupDataset::updateLookupForQuark(quark)
    def self.updateLookupForQuark(quark)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(quark["uuid"])
        SelectionLookupDatabaseIO::addRecord("quark", quark["uuid"], quark["uuid"])
        SelectionLookupDatabaseIO::addRecord("quark", quark["uuid"], Quarks::toString(quark))
        SelectionLookupDatabaseIO::addRecord("quark", quark["uuid"], quark["leptonfilename"])
    end

    # SelectionLookupDataset::updateLookupForTag(tag)
    def self.updateLookupForTag(tag)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(tag["uuid"])
        SelectionLookupDatabaseIO::addRecord("tag", tag["uuid"], tag["uuid"])
        SelectionLookupDatabaseIO::addRecord("tag", tagt["uuid"], Tags::toString(tag).downcase)
    end

    # SelectionLookupDataset::updateLookupForOperationalListing(node)
    def self.updateLookupForOperationalListing(node)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(node["uuid"])
        SelectionLookupDatabaseIO::addRecord("opsnode", node["uuid"], node["uuid"])
        SelectionLookupDatabaseIO::addRecord("opsnode", node["uuid"], OperationalListings::toString(node).downcase)
    end

    # SelectionLookupDataset::updateLookupForEncyclopediaListing(node)
    def self.updateLookupForEncyclopediaListing(node)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(node["uuid"])
        SelectionLookupDatabaseIO::addRecord("encyclopedianode", node["uuid"], node["uuid"])
        SelectionLookupDatabaseIO::addRecord("encyclopedianode", node["uuid"], EncyclopediaListings::toString(node).downcase)
    end

    # SelectionLookupDataset::updateLookupForAsteroid(asteroid)
    def self.updateLookupForAsteroid(asteroid)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(asteroid["uuid"])
        SelectionLookupDatabaseIO::addRecord("asteroid", asteroid["uuid"], asteroid["uuid"])
        SelectionLookupDatabaseIO::addRecord("asteroid", asteroid["uuid"], Asteroids::toString(asteroid).downcase)
    end

    # SelectionLookupDataset::updateLookupForWave(wave)
    def self.updateLookupForWave(wave)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], Waves::toString(wave).downcase)
    end

    # ---------------------------------------------------------

    # SelectionLookupDataset::rebuildNGX15sLookup(verbose)
    def self.rebuildNGX15sLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
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
        db.execute "delete from lookup where _objecttype_=?", ["quark"]

        Quarks::quarks()
            .each{|quark|
                if verbose then
                    puts "quark: #{quark["uuid"]} , #{Quarks::toString(quark)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "quark", quark["uuid"], quark["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "quark", quark["uuid"], Quarks::toString(quark))
                SelectionLookupDatabaseIO::addRecord2(db, "quark", quark["uuid"], quark["leptonfilename"])
            }

        db.close
    end

    # SelectionLookupDataset::rebuildTagsLookup(verbose)
    def self.rebuildTagsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["tag"]

        Tags::tags()
            .each{|tag|
                if verbose then
                    puts "tag: #{tag["uuid"]} , #{Tags::toString(tag)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "tag", tag["uuid"], tag["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "tag", tag["uuid"], Tags::toString(tag))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildOperationalListingsLookup(verbose)
    def self.rebuildOperationalListingsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["opsnode"]

        OperationalListings::listings()
            .each{|node|
                if verbose then
                    puts "ops node: #{node["uuid"]} , #{OperationalListings::toString(node)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "opsnode", node["uuid"], node["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "opsnode", node["uuid"], OperationalListings::toString(node))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildEncyclopediaListingsLookup(verbose)
    def self.rebuildEncyclopediaListingsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["encyclopedianode"]

        EncyclopediaListings::listings()
            .each{|node|
                if verbose then
                    puts "encyclopedia node: #{node["uuid"]} , #{EncyclopediaListings::toString(node)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "encyclopedianode", node["uuid"], node["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "encyclopedianode", node["uuid"], EncyclopediaListings::toString(node))
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
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup", []
        db.close

        SelectionLookupDataset::rebuildNGX15sLookup(verbose)
        SelectionLookupDataset::rebuildQuarksLookup(verbose)
        SelectionLookupDataset::rebuildTagsLookup(verbose)
        SelectionLookupDataset::rebuildOperationalListingsLookup(verbose)
        SelectionLookupDataset::rebuildEncyclopediaListingsLookup(verbose)
        SelectionLookupDataset::rebuildAsteroidsLookup(verbose)
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
