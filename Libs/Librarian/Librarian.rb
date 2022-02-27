# require "/Users/pascal/Galaxy/Software/Librarian/Librarian.rb"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'find'

# ------------------------------------------------------------------------

class LibrarianDataBlobs

    # LibrarianDataBlobs::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/Datablobs"
    end

    # LibrarianDataBlobs::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # LibrarianDataBlobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{LibrarianDataBlobs::repositoryFolderPath()}/#{nhash[7, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # LibrarianDataBlobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{LibrarianDataBlobs::repositoryFolderPath()}/#{nhash[7, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        if File.exists?(filepath) then
            return IO.read(filepath)
        end
        nil
    end
end

=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, nhash, blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

class LibrarianElizabeth

    def initialize()
    end

    def commitBlob(blob)
        LibrarianDataBlobs::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = LibrarianDataBlobs::getBlobOrNull(nhash)
        return blob if blob
        raise "(LibrarianElizabeth, readBlobErrorIfNotFound, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class LibrarianObjects

    # LibrarianObjects::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/objects.sqlite3"
    end

    # LibrarianObjects::validMikuTypes()
    def self.validMikuTypes()
        [
            "Atom",
            "Nx31",
            "TxCalendarItem",
            "TxDated",
            "TxDrop",
            "TxFloat",
            "TxTodo",
            "Wave"
        ]
    end

    # LibrarianObjects::objects2RepositoryFolderPath()
    def self.objects2RepositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/Objects"
    end

    # LibrarianObjects::objectsFilepathsEnumerator()
    def self.objectsFilepathsEnumerator()
        Enumerator.new do |filepaths|
            Find.find(LibrarianObjects::objects2RepositoryFolderPath()) do |location|
                next if !File.file?(location)
                next if location[-5, 5] != ".json"
                filepaths << location
            end
        end
    end

    # LibrarianObjects::objectUUIDToFilepath(uuid)
    def self.objectUUIDToFilepath(uuid)
        trace = Digest::SHA1.hexdigest(uuid)
        fragment = trace[0, 2]
        folder2 = "#{LibrarianObjects::objects2RepositoryFolderPath()}/#{fragment}"
        if !File.exists?(folder2) then
            FileUtils.mkdir(folder2)
        end
        filepath = "#{folder2}/#{trace}.json"
        filepath
    end

    # ------------------------------------------------------------------------
    # Below: Public Interface

    # LibrarianObjects::objects()
    def self.objects()
        db = SQLite3::Database.new(LibrarianObjects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_", []) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # LibrarianObjects::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(LibrarianObjects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # LibrarianObjects::getObjectsByMikuTypeLimitByOrdinal(mikuType, n)
    def self.getObjectsByMikuTypeLimitByOrdinal(mikuType, n)
        db = SQLite3::Database.new(LibrarianObjects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=? order by _ordinal_ limit ?", [mikuType, n]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # LibrarianObjects::commit(object)
    def self.commit(object)
        raise "(error: 8e53e63e-57fe-4621-a1c6-a7b4ad5d23a7, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 016668dd-cb66-4ba1-9546-2fe05ee62fc6, missing attribute mikuType)" if object["mikuType"].nil?
        raise "(error: 23273f9d-b6a0-4cdc-a826-b10c3a3955c5, non valid mikuType: #{object["mikuType"]})" if !LibrarianObjects::validMikuTypes().include?(object["mikuType"])

        ordinal = object["ordinal"] || 0

        db = SQLite3::Database.new(LibrarianObjects::databaseFilepath())
        db.execute "delete from _objects_ where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_objectuuid_, _mikuType_, _object_, _ordinal_) values (?,?,?,?)", [object["uuid"], object["mikuType"], JSON.generate(object), ordinal]
        db.close
    end

    # LibrarianObjects::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(LibrarianObjects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _objects_ where _objectuuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # LibrarianObjects::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(LibrarianObjects::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _objects_ where _objectuuid_=?", [uuid]
        db.close
    end
end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class LibrarianNotes

    # LibrarianNotes::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Librarian/Data/notes.sqlite3"
    end

    # LibrarianNotes::getObjectNotes(objectuuid)
    def self.getObjectNotes(objectuuid)
        db = SQLite3::Database.new(LibrarianNotes::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _notes_ where _objectuuid_=?", [objectuuid]) do |row|
            answer << {
                "noteuuid"   => row['_noteuuid_'],
                "objectuuid" => row['_objectuuid_'],
                "unixtime"   => row['_unixtime_'],
                "text"       => row['_text_'],
            }
        end
        db.close
        answer
    end

    # LibrarianNotes::addNote(objectuuid, text)
    def self.addNote(objectuuid, text)
        noteuuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        db = SQLite3::Database.new(LibrarianNotes::databaseFilepath())
        db.execute "insert into _notes_ (_noteuuid_, _objectuuid_, _unixtime_, _text_) values (?,?,?,?)", [noteuuid, objectuuid, unixtime, text]
        db.close
    end

    # LibrarianNotes::deleteNote(noteuuid)
    def self.deleteNote(noteuuid)
        db = SQLite3::Database.new(LibrarianNotes::databaseFilepath())
        db.execute "delete from _notes_ where _noteuuid_=?", [noteuuid]
        db.close
    end
end

class LibrarianNonStandardOps
    
    # LibrarianNonStandardOps::commitFileReturnPartsHashs(filepath)
    def self.commitFileReturnPartsHashs(filepath)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << LibrarianDataBlobs::putBlob(blob)
        end
        f.close()
        hashes
    end
end

