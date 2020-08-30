
# encoding: UTF-8

class NyxFileSystemElementsMapping

    # NyxFileSystemElementsMapping::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-FileSystem-Elements-Mapping.sqlite3"
    end

    # NyxFileSystemElementsMapping::register(objectuuid, elementname, location)
    def self.register(objectuuid, elementname, location)
        db = SQLite3::Database.new(NyxFileSystemElementsMapping::databaseFilepath())
        db.execute "delete from mapping where _objectuuid_=?", [objectuuid]
        db.execute "insert into mapping (_objectuuid_, _name_, _location_) values ( ?, ?, ? )", [objectuuid, elementname, location]
        db.close
    end

    # NyxFileSystemElementsMapping::removeRecordByObjectUUID(objectuuid)
    def self.removeRecordByObjectUUID(objectuuid)
        db = SQLite3::Database.new(NyxFileSystemElementsMapping::databaseFilepath())
        db.execute "delete from mapping where _objectuuid_=?", [objectuuid]
        db.close
    end

    # NyxFileSystemElementsMapping::getStoredLocationForObjectUUIDOrNull(objectuuid)
    def self.getStoredLocationForObjectUUIDOrNull(objectuuid)
        db = SQLite3::Database.new(NyxFileSystemElementsMapping::databaseFilepath())
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from mapping where _objectuuid_=?" , [objectuuid] ) do |row|
            answer = row['_location_']
        end
        db.close
        answer
    end

    # NyxFileSystemElementsMapping::records()
    def self.records()
        db = SQLite3::Database.new(NyxFileSystemElementsMapping::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from mapping" , [] ) do |row|
            answer << {
                "objectuuid" => row['_objectuuid_'],
                "name"       => row['_name_'],
                "location"   => row['_location_'],
            }
        end
        db.close
        answer
    end

    # NyxFileSystemElementsMapping::fsck()
    def self.fsck()
        NyxFileSystemElementsMapping::records().each{|record|
            if NyxObjects2::getOrNull(record["objectuuid"]).nil? then
                NyxFileSystemElementsMapping::removeRecordByObjectUUID(record["objectuuid"])
                next
            end
            if !File.exists?(record["location"]) then
                puts "Incorrect record:"
                puts JSON.pretty_generate(record)
                exit
            end
        }
    end
end
