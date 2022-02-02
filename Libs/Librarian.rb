
# encoding: UTF-8

# --------------------------------------------------------------------------------------
# This file is used both in Catalyst and Nyx. The Catalyst version is the master version
# --------------------------------------------------------------------------------------

require 'sqlite3'

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

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

class LibrarianMikuAtomElizabeth

    # create table _datablobs_ (_nhash_ string primary key, _data_ blob)

    def initialize(mikufilepath)
        @mikufilepath = mikufilepath
    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(@mikufilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _datablobs_ where _nhash_=?", [nhash]
        db.execute "insert into _datablobs_ (_nhash_, _data_) values (?,?)", [nhash, blob]
        db.close
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = nil

        db = SQLite3::Database.new(@mikufilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _datablobs_ where _nhash_=?", [nhash]) do |row|
            blob = row['_data_']
        end
        db.close

        return blob if blob

        blob = Atoms10BlobService::getBlobOrNull(nhash)
        if blob then
            commitBlob(blob)
            return blob
        end

        blob = Librarian::theGreatBlobFinder(nhash)
        if blob then
            commitBlob(blob)
            return blob
        end

        raise "[Elizabeth error: 1c2f2aa8-9ead-47fa-b09f-4927a89d9687, looking for nhash: #{nhash}, at mikufilepath: #{@mikufilepath}, did not find it and did not find it in Atoms10BlobService either]"
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

class LibrarianUuidClassifierOrdinalIndex

    # LibrarianUuidClassifierOrdinalIndex::setRecord(uuid, classifier, ordinal)
    def self.setRecord(uuid, classifier, ordinal)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/uuid-classifier-ordinal.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _index_ where _uuid_=?", [uuid]
        db.execute "insert into _index_ (_uuid_, _classifier_, _ordinal_) values (?,?,?)", [uuid, classifier, ordinal]
        db.commit 
        db.close
    end

    # LibrarianUuidClassifierOrdinalIndex::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/uuid-classifier-ordinal.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _index_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # LibrarianUuidClassifierOrdinalIndex::getUUIDs(classifier)
    def self.getUUIDs(classifier)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/uuid-classifier-ordinal.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select * from _index_ where _classifier_=?", [classifier]) do |row|
            uuids << row['_uuid_']
        end
        db.close
        uuids
    end

    # LibrarianUuidClassifierOrdinalIndex::getUUIDsLimitByOrdinal(classifier, n)
    def self.getUUIDsLimitByOrdinal(classifier, n)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/uuid-classifier-ordinal.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select * from _index_ where _classifier_=? order by _ordinal_ limit ?", [classifier, n]) do |row|
            uuids << row['_uuid_']
        end
        db.close
        uuids
    end

    # LibrarianUuidClassifierOrdinalIndex::batch()
    def self.batch()
        Librarian::mikufilepaths().each{|filepath|
            uuid       = Librarian::getValueAtFilepathOrNull(filepath, "uuid")
            classifier = Librarian::getValueAtFilepathOrNull(filepath, "classification")
            ordinal    = Librarian::getValueAtFilepathOrNull(filepath, "ordinal") || 0
            LibrarianUuidClassifierOrdinalIndex::setRecord(uuid, classifier, ordinal)
        }
    end
end

class Librarian

    # ------------------------------------------------
    # Private Utils
    # ------------------------------------------------

    # Librarian::LibrarianRepositoryFolderpath()
    def self.LibrarianRepositoryFolderpath()
        "/Users/pascal/Galaxy/Librarian"
    end

    # Librarian::MikuFilesRootFolderpath()
    def self.MikuFilesRootFolderpath()
        "#{Librarian::LibrarianRepositoryFolderpath()}/MikuFiles"
    end

    # Librarian::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Librarian::newMikuFilename()
    def self.newMikuFilename()
        "#{Librarian::timeStringL22()}.miku"
    end

    # Librarian::filenameToNewFilepath(filename)
    def self.filenameToNewFilepath(filename)
        folder1 = Librarian::MikuFilesRootFolderpath()
        folder2 = LucilleCore::indexsubfolderpath2(folder1, 250)
        "#{folder2}/#{filename}"
    end

    # Librarian::classifiers()
    def self.classifiers()
        [
            "CalendarItem",
            "TxDated",
            "TxDrop",
            "TxFloat",
            "TxSpaceship",
            "TxTodo",
            "TxWorkItem",
            "Wave",
            "PureData",
            "PublicEvent",
            "PascalPrivateLog",
            "TxTest"
        ]
    end

    # Librarian::interactivelySelectOneClassifier()
    def self.interactivelySelectOneClassifier()
        classifier = LucilleCore::selectEntityFromListOfEntitiesOrNull("classifier", Librarian::classifiers())
        if classifier then
            classifier 
        else
            Librarian::interactivelySelectOneClassifier()
        end
    end

    # Librarian::mikufilepaths()
    def self.mikufilepaths()
        Enumerator.new do |filepaths|
            Find.find(Librarian::MikuFilesRootFolderpath()) do |location|
                next if !File.file?(location)
                next if location[-5, 5] != ".miku"
                filepaths << location
            end
        end
    end

    # Librarian::theGreatBlobFinder(nhash)
    def self.theGreatBlobFinder(nhash)
        puts "The great blob finder: #{nhash}"
        Librarian::mikufilepaths().each{|filepath|
            blob = nil
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _datablobs_ where _nhash_=?", [nhash]) do |row|
                blob = row['_data_']
            end
            db.close
            return blob if blob
        }
        nil
    end

    # ------------------------------------------------
    # Private File Lookup Management
    # ------------------------------------------------

    # Librarian::uuidToFilepathOrNull(uuid)
    def self.uuidToFilepathOrNull(uuid)

        filepath = KeyValueStore::getOrNull(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{uuid}")
        if filepath and File.exists?(filepath) then
            if Librarian::getValueAtFilepathOrNull(filepath, "uuid") == uuid then
                return filepath
            end
        end

        useTheForce = lambda {|uuid|
            puts "Using the Force to find filepath for uuid: #{uuid}"
            Librarian::mikufilepaths()
                .select{|filepath| Librarian::getValueAtFilepathOrNull(filepath, "uuid") == uuid }
                .first
        }

        filepath = useTheForce.call(uuid)

        if filepath.nil? then
            return nil
        end

        KeyValueStore::set(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{uuid}", filepath)

        filepath
    end

    # Librarian::batchPrecomputeUuidToFilepathLookup()
    def self.batchPrecomputeUuidToFilepathLookup()
        Librarian::mikufilepaths().each{|filepath|
            fileuuid = Librarian::getValueAtFilepathOrNull(filepath, "uuid")
            KeyValueStore::set(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{fileuuid}", filepath)
        }
    end

    # ------------------------------------------------
    # Private File Attributes IO
    # ------------------------------------------------

    # Librarian::getValueAtFilepathOrNull(filepath, key)
    def self.getValueAtFilepathOrNull(filepath, key)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _table1_ where _name_=?", [key]) do |row|
            answer = row['_data_']
        end
        db.close
        answer
    end

    # Librarian::getShapeXedAtFilepath1(filepath, shapeX)
    def self.getShapeXedAtFilepath1(filepath, shapeX)
        object = {}

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true

        shapeX.each{|shape|
            value = nil
            db.execute("select * from _table1_ where _name_=?", [shape[0]]) do |row|
                value = row['_data_']
                if shape[1] == "integer" then
                    value = value.to_i
                end
                if shape[1] == "float" then
                    value = value.to_f
                end
                if shape[1] == "json" then
                    value = JSON.parse(value)
                end
            end
            object[shape[0]] = value
        }

        db.close

        object
    end

    # Librarian::setValueAtFilepath(filepath, key, value)
    def self.setValueAtFilepath(filepath, key, value)
        db = SQLite3::Database.new(filepath)
        db.execute "delete from _table1_ where _name_=?", [key]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, key, value]
        db.close

        if key == "classification" then
            uuid       = Librarian::getValueAtFilepathOrNull(filepath, "uuid")
            classifier = Librarian::getValueAtFilepathOrNull(filepath, "classification")
            ordinal    = Librarian::getValueAtFilepathOrNull(filepath, "ordinal") || 0
            LibrarianUuidClassifierOrdinalIndex::setRecord(uuid, classifier, ordinal)
        end

        if key == "ordinal" then
            uuid       = Librarian::getValueAtFilepathOrNull(filepath, "uuid")
            classifier = Librarian::getValueAtFilepathOrNull(filepath, "classification")
            ordinal    = Librarian::getValueAtFilepathOrNull(filepath, "ordinal") || 0
            LibrarianUuidClassifierOrdinalIndex::setRecord(uuid, classifier, ordinal)
        end
    end

    # Librarian::setShapeXedAtFilepath1(filepath, object, shapeX)
    def self.setShapeXedAtFilepath1(filepath, object, shapeX)
        shapeX.each{|shape|
            keyname = shape[0]
            value   = object[keyname]
            if shape[1] == "json" then
                value = JSON.generate(value)
            end
            Librarian::setValueAtFilepath(filepath, keyname, value)
        }
    end

    # ------------------------------------------------------------------------------------------------

    # ------------------------------------------------
    # Public Files Creation, Updates and Deletion
    # ------------------------------------------------

    # Librarian::setValue(uuid, key, value)
    def self.setValue(uuid, key, value)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::setValueAtFilepath(filepath, key, value)
    end

    # Librarian::getValueOrNull(filepath, key)
    def self.getValueOrNull(filepath, key)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::getValueAtFilepathOrNull(filepath, key)
    end

    # Librarian::issueNewFileMxClassic(uuid, description, unixtime, datetime, classifier, atom, domainx, ordinal)
    def self.issueNewFileMxClassic(uuid, description, unixtime, datetime, classifier, atom, domainx, ordinal)

        filename = Librarian::newMikuFilename()
        filepath = Librarian::filenameToNewFilepath(filename)

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "create table _table1_ (_recorduuid_ text primary key, _unixtime_ float, _name_ string, _data_ blob)", []
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "mikuType", "MxClassic"]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "uuid", uuid]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "description", description]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "unixtime", unixtime]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "datetime", datetime]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classifier]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "atom", JSON.generate(atom)]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "domainx", domainx]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "ordinal", ordinal]

        db.execute "create table _datablobs_ (_nhash_ string primary key, _data_ blob)", []
        db.execute "create table _notes_ (_uuid_ text primary key, _unixtime_ float, _text_ text)", []
        db.close

        # Caching the location of that file
        KeyValueStore::set(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{uuid}", filepath)

        # Registering the (uuid, classifier, ordinal) tuple at the collection index
        LibrarianUuidClassifierOrdinalIndex::setRecord(uuid, classifier, 0)

        # Running Fsck on the file to bring atom aion-point datablobs into the file
        Librarian::fsckFilepath(filepath)

        filepath
    end

    # Librarian::getMikuFileOrNull(uuid) # Object
    def self.getMikuFileOrNull(uuid)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return nil if filepath.nil?

        miku = {}
        miku["uuid"] = Librarian::getValueOrNull(filepath, "uuid")

        mikuType = Librarian::getValueOrNull(filepath, "mikuType")

        miku["mikuType"] = mikuType

        if mikuType == "MxClassic" then
            miku["description"]    = Librarian::getValueOrNull(filepath, "description")
            miku["unixtime"]       = Librarian::getValueOrNull(filepath, "unixtime")
            miku["datetime"]       = Librarian::getValueOrNull(filepath, "datetime")
            miku["classification"] = Librarian::getValueOrNull(filepath, "classification")
            miku["atom"]           = JSON.parse(Librarian::getValueOrNull(filepath, "atom"))
            miku["ordinal"]        = Librarian::getValueOrNull(filepath, "ordinal")
            miku["domainx"]        = Librarian::getValueOrNull(filepath, "domainx")
            return miku
        end

        raise "(error: 143183d3-db8f)"
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        FileUtils.rm(filepath)
        LibrarianUuidClassifierOrdinalIndex::deleteRecord(uuid)
    end

    # ------------------------------------------------
    # Public Collections
    # ------------------------------------------------

    # Librarian::classifierToShapeXeds(classifier, shapeX)
    def self.classifierToShapeXeds(classifier, shapeX)
        LibrarianUuidClassifierOrdinalIndex::getUUIDs(classifier)
            .map{|uuid|
                filepath = Librarian::uuidToFilepathOrNull(uuid)
                if filepath then
                    Librarian::getShapeXedAtFilepath1(filepath, shapeX)
                else
                    LibrarianUuidClassifierOrdinalIndex::deleteRecord(uuid)
                    nil
                end
            }
            .compact
    end

    # Librarian::classifierToShapeXedsLimitByOrdinal(classifier, shapeX, n)
    def self.classifierToShapeXedsLimitByOrdinal(classifier, shapeX, n)
        LibrarianUuidClassifierOrdinalIndex::getUUIDsLimitByOrdinal(classifier, n)
            .map{|uuid|
                filepath = Librarian::uuidToFilepathOrNull(uuid)
                if filepath then
                    Librarian::getShapeXedAtFilepath1(filepath, shapeX)
                else
                    nil
                end
            }
            .compact
    end

    # ------------------------------------------------
    # Public Atom Access
    # ------------------------------------------------

    # Librarian::accessMikuAtomWithOptionToEdit(uuid, atom)
    def self.accessMikuAtomWithOptionToEdit(uuid, atom)

        mikufilepath = Librarian::uuidToFilepathOrNull(uuid)

        if mikufilepath.nil? then
            puts "I am trying to access miku/atom for"
            puts JSON.pretty_generate(miku)
            puts "But can't find the file 🤔"
            puts "Aborting operation"
            LucilleCore::pressEnterToContinue()
            return
        end

        if atom["type"] == "description-only" then
            puts "atom: description-only (atom payload is empty)"
            LucilleCore::pressEnterToContinue()
            return
        end
        if atom["type"] == "text" then
            text1 = atom["payload"]
            text2 = Atoms0Utils::editTextSynchronously(text1)
            if text1 != text2 then
                atom["payload"] = text2
                Librarian::setValueAtFilepath(mikufilepath, "atom", JSON.generate(atom))
            end
            return
        end
        if atom["type"] == "url" then
            Atoms0Utils::openUrlUsingSafari(atom["payload"])
            if LucilleCore::askQuestionAnswerAsBoolean("> edit url ? ", false) then
                url = LucilleCore::askQuestionAnswerAsString("url (empty to abort) : ")
                if url.size > 0 then
                    atom["payload"] = url
                Librarian::setValueAtFilepath(mikufilepath, "atom", JSON.generate(atom))
                end
            end
            return
        end
        if atom["type"] == "aion-point" then
            AionCore::exportHashAtFolder(LibrarianMikuAtomElizabeth.new(mikufilepath), atom["payload"], "/Users/pascal/Desktop")
            if LucilleCore::askQuestionAnswerAsBoolean("> edit aion-point ? ", false) then
                location = Atoms0Utils::interactivelySelectDesktopLocationOrNull()
                return if location.nil?
                nhash = AionCore::commitLocationReturnHash(LibrarianMikuAtomElizabeth.new(mikufilepath), location)
                Atoms0Utils::moveFileToBinTimeline(location)
                atom["payload"] = nhash
                Librarian::setValueAtFilepath(mikufilepath, "atom", JSON.generate(atom))
            end
            return
        end
        if atom["type"] == "marble" then
            marbleId = atom["payload"]
            location = Atoms0Utils::marbleLocationOrNullUsingCache(marbleId)
            if location then
                puts "found marble at: #{location}"
                system("open '#{File.dirname(location)}'")
                return
            end
            puts "I could not find the location of the marble in the cache"
            return if !LucilleCore::askQuestionAnswerAsBoolean("Would you like me to use the Force ? ")
            location = Atoms0Utils::marbleLocationOrNullUseTheForce(marbleId)
            if location then
                puts "found marble at: #{location}"
                system("open '#{File.dirname(location)}'")
            end
            return
        end
        if atom["type"] == "managed-folder" then
            foldername = atom["payload"]
            folderpath = "#{Atoms0Utils::managedFoldersRepositoryPath()}/#{foldername}"
            puts "opening core data folder #{folderpath}"
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return
        end
        if atom["type"] == "unique-string" then
            payload = atom["payload"]
            puts "unique string: #{payload}"
            location = Atoms0Utils::atlas(payload)
            if location then
                puts "location: #{location}"
                if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                    system("open '#{location}'")
                end
            else
                puts "[Atoms5] Could not find location for unique string: #{payload}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "(33f07691-5cd0-4674-b5e0-5b5ed3142c7a, uuid: #{uuid})"
    end

    # Librarian::accessMikuAtom(miku)
    def self.accessMikuAtom(miku)
        Librarian::accessMikuAtomWithOptionToEdit(miku["uuid"], miku["atom"])
    end

    # ------------------------------------------------
    # Notes
    # ------------------------------------------------

    # Librarian::notes(uuid)
    def self.notes(uuid)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return [] if filepath.nil?
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        notes = []
        # create table _notes_ (_uuid_ text primary key, _unixtime_ float, _text_ text)
        db.execute("select * from _notes_ order by _unixtime_", []) do |row|
            notes << {
                "uuid"     => row['_uuid_'],
                "unixtime" => row['_unixtime_'],
                "text"     => row['_text_']
            }
        end
        db.close
        notes
    end

    # Librarian::addNote(mukiuuid, noteuuid, unixtime, text)
    def self.addNote(mukiuuid, noteuuid, unixtime, text)
        filepath = Librarian::uuidToFilepathOrNull(mukiuuid)
        return [] if filepath.nil?
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # create table _notes_ (_uuid_ text primary key, _unixtime_ float, _text_ text)
        db.execute "insert into _notes_ (_uuid_, _unixtime_, _text_) values (?,?,?)", [noteuuid, unixtime, text]
        db.close
    end

    # Librarian::deleteNote(mukiuuid, noteuuid)
    def self.deleteNote(mukiuuid, noteuuid)
        filepath = Librarian::uuidToFilepathOrNull(mukiuuid)
        return if filepath.nil?
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _notes_ where _uuid_=?", [noteuuid]
        db.close
    end

    # ------------------------------------------------
    # Public fsck
    # ------------------------------------------------

    # Librarian::fsckFileAtom(filepath, atom) : Boolean
    def self.fsckFileAtom(mikufilepath, atom)
        if atom["type"] == "description-only" then
            return true
        end
        if atom["type"] == "text" then
            return true
        end
        if atom["type"] == "url" then
            return true
        end
        if atom["type"] == "aion-point" then
            nhash = atom["payload"]
            return AionFsck::structureCheckAionHash(LibrarianMikuAtomElizabeth.new(mikufilepath), nhash)
        end
        if atom["type"] == "marble" then
            return true
        end
        if atom["type"] == "managed-folder" then
            foldername = atom["payload"]
            return File.exists?("#{Atoms0Utils::managedFoldersRepositoryPath()}/#{foldername}")
        end
        if atom["type"] == "unique-string" then
            # Technically we should be checking if the target exists, but that takes too long
            return true
        end
        raise "(2b5f9252-cfc0-49e4-beee-9741072362c5: non recognised atom type: #{atom})"
    end

    # Librarian::fsckFilepath(filepath)
    def self.fsckFilepath(filepath)
        atom = JSON.parse(Librarian::getValueAtFilepathOrNull(filepath, "atom"))
        status = Librarian::fsckFileAtom(filepath, atom)
        if !status then
            puts "failing:".red
            puts "filepath: #{filepath}".red
            puts "atom: #{JSON.pretty_generate(atom)}".red
            LucilleCore::pressEnterToContinue()
        end
        status
    end

    # Librarian::fsck()
    def self.fsck()
        Librarian::mikufilepaths().each{|filepath|
            puts filepath
            Librarian::fsckFilepath(filepath)
        }
        puts "fsck completed".green
        LucilleCore::pressEnterToContinue()
    end
end
