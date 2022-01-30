
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

class Librarian

    # ------------------------------------------------
    # Private Utils
    # ------------------------------------------------

    # Librarian::LibrarianRepositoryFolderpath()
    def self.LibrarianRepositoryFolderpath()
        "/Users/pascal/Galaxy/Librarian"
    end

    # Librarian::MikuFilesFolderpath()
    def self.MikuFilesFolderpath()
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

    # Librarian::classifiers()
    def self.classifiers()
        [
            "CalendarItem",
            "CatalystTxDated",
            "CatalystTxDrop",
            "CatalystTxFloat",
            "CatalystTxSpaceship",
            "CatalystTxTodo",
            "CatalystWorkItem",
            "CatalystWave",
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

    # Librarian::readMikuObjectFromMikuFileOrError(filepath)
    def self.readMikuObjectFromMikuFileOrError(filepath)

        uuid           = nil
        version        = nil
        description    = nil
        unixtime       = nil
        datetime       = nil
        classification = nil
        atom           = nil
        notes          = nil
        extras         = nil

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true

        db.execute("select * from _table1_ where _name_=?", ["uuid"]) do |row|
            uuid = row['_data_']
        end

        db.execute("select * from _table1_ where _name_=?", ["version"]) do |row|
            version = row['_data_']
        end

        db.execute("select * from _table1_ where _name_=?", ["description"]) do |row|
            description = row['_data_']
        end

        db.execute("select * from _table1_ where _name_=?", ["unixtime"]) do |row|
            unixtime = row['_data_']
        end

        db.execute("select * from _table1_ where _name_=?", ["datetime"]) do |row|
            datetime = row['_data_']
        end

        db.execute("select * from _table1_ where _name_=?", ["classification"]) do |row|
            classification = row['_data_']
        end

        db.execute("select * from _table1_ where _name_=?", ["atom"]) do |row|
            atom = JSON.parse(row['_data_'])
        end

        notes = []
        db.execute("select * from _table1_ where _name_=? order by _unixtime_", ["note"]) do |row|
            notes << {
                "uuid"     => row["_recorduuid_"],
                "unixtime" => row["_unixtime_"],
                "text"     => row["_data_"]
            }
        end

        db.execute("select * from _table1_ where _name_=?", ["extras"]) do |row|
            extras = JSON.parse(row['_data_'])
        end

        db.close

        {
            "uuid"           => uuid,
            "version"        => version,
            "description"    => description,
            "unixtime"       => unixtime,
            "datetime"       => datetime,
            "classification" => classification,
            "atom"           => atom,
            "notes"          => notes,
            "extras"         => extras,
        }
    end

    # Librarian::interactivelyCreateNewMikuOrNull()
    def self.interactivelyCreateNewMikuOrNull()
        uuid           = SecureRandom.uuid
        description    = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        unixtime       = Time.new.to_f
        datetime       = Time.new.utc.iso8601
        classification = Librarian::interactivelySelectOneClassifier()
        atom           = Atoms5::interactivelyCreateNewAtomOrNull()

        filepath = Librarian::spawnNewMikuFileOrError(uuid, description, unixtime, datetime, classification, atom, extras)

        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::mikufilepaths()
    def self.mikufilepaths()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/Librarian/MikuFiles")
    end

    # ------------------------------------------------
    # Private File Lookup Management
    # ------------------------------------------------

    # Librarian::uuidToFilepathOrNull(uuid)
    def self.uuidToFilepathOrNull(uuid)

        filepath = KeyValueStore::getOrNull(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{uuid}")
        if filepath and File.exists?(filepath) then
            miku = Librarian::readMikuObjectFromMikuFileOrError(filepath)
            if miku["uuid"] == uuid then
                return filepath
            end
        end

        useTheForce = lambda {|uuid|
            puts "Using the Force to find filepath for uuid: #{uuid}"
            LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/Librarian/MikuFiles")
                .select{|filepath|
                    miku = Librarian::readMikuObjectFromMikuFileOrError(filepath)
                    miku["uuid"] == uuid
                }
                .first
        }

        filepath = useTheForce.call(uuid)

        return nil if filepath.nil?

        KeyValueStore::set(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{uuid}", filepath)

        filepath
    end

    # Librarian::precomputeUuidToFilepathLookup()
    def self.precomputeUuidToFilepathLookup()
        Librarian::mikufilepaths().each{|filepath|
            miku = Librarian::readMikuObjectFromMikuFileOrError(filepath)
            uuid = miku["uuid"]
            KeyValueStore::set(nil, "b3994c86-f2ed-485f-8423-6ff6f049382e:#{uuid}", filepath)
        }
    end

    # ------------------------------------------------
    # Private Updates Files
    # ------------------------------------------------

    # Librarian::updateMikuDescriptionAtFilepath(filepath, description)
    def self.updateMikuDescriptionAtFilepath(filepath, description)
        db = SQLite3::Database.new(filepath)
        db.execute "update _table1_ set _data_=? where _name_=?", [description, "description"]
        db.close
    end

    # Librarian::updateMikuDatetimeAtFilepath(filepath, datetime)
    def self.updateMikuDatetimeAtFilepath(filepath, datetime)
        db = SQLite3::Database.new(filepath)
        db.execute "update _table1_ set _data_=? where _name_=?", [datetime, "datetime"]
        db.close
    end

    # Librarian::updateMikuClassificationAtFilepath(filepath, classification)
    def self.updateMikuClassificationAtFilepath(filepath, classification)
        db = SQLite3::Database.new(filepath)
        db.execute "update _table1_ set _data_=? where _name_=?", [classification, "classification"]
        db.close
    end

    # Librarian::updateMikuAtomAtFilepath(filepath, atom)
    def self.updateMikuAtomAtFilepath(filepath, atom)
        db = SQLite3::Database.new(filepath)
        db.execute "update _table1_ set _data_=? where _name_=?", [JSON.generate(atom), "atom"]
        db.close
    end

    # Librarian::updateMikuExtrasAtFilepath(filepath, extras)
    def self.updateMikuExtrasAtFilepath(filepath, extras)
        db = SQLite3::Database.new(filepath)
        db.execute "update _table1_ set _data_=? where _name_=?", [JSON.generate(extras), "extras"]
        db.close
    end

    # ------------------------------------------------
    # Private Index Management
    # ------------------------------------------------

    # Librarian::updateIndexFile(uuid, classifier, ordinal)
    def self.updateIndexFile(uuid, classifier, ordinal)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/librarian-collections-index.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _index_ where _uuid_=?", [uuid]
        db.execute "insert into _index_ (_uuid_, _classifier_, _ordinal_) values (?,?,?)", [uuid, classifier, ordinal]
        db.commit 
        db.close
    end

    # Librarian::batchUpdateIndexFile()
    def self.batchUpdateIndexFile()
        Librarian::mikufilepaths().each{|filepath|
            miku = Librarian::readMikuObjectFromMikuFileOrError(filepath)
            puts JSON.pretty_generate(miku)
            uuid       = miku["uuid"]
            classifier = miku["classification"]
            ordinal    = miku["extras"]["ordinal"] || 0
            Librarian::updateIndexFile(uuid, classifier, ordinal)
        }
    end

    # Librarian::getUUIDsforClassifier(classifier)
    def self.getUUIDsforClassifier(classifier)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/librarian-collections-index.sqlite3")
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

    # Librarian::getUUIDSForClassifierLimitByOrdinal(classifier, n)
    def self.getUUIDSForClassifierLimitByOrdinal(classifier, n)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/Librarian/librarian-collections-index.sqlite3")
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

    # ------------------------------------------------
    # Public Creation
    # ------------------------------------------------

    # Librarian::spawnNewMikuFileOrError(uuid, description, unixtime, datetime, classifier, atom, extras) # filepath
    def self.spawnNewMikuFileOrError(uuid, description, unixtime, datetime, classifier, atom, extras)
        # decide filename
        filename = Librarian::newMikuFilename()

        # decide filepath
        filepath = "#{Librarian::MikuFilesFolderpath()}/#{filename}"


        # create table _table1_ (_recorduuid_ text primary key, _unixtime_ float, _name_ string, _data_ blob)

        # create file
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "create table _table1_ (_recorduuid_ text primary key, _unixtime_ float, _name_ string, _data_ blob)", []

        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "uuid", uuid]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "version", "20220128"]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "description", description]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "unixtime", unixtime]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "datetime", datetime]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classifier]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "atom", JSON.generate(atom)]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "extras", JSON.generate(extras)]

        db.close

        # checks

        Librarian::updateIndexFile(uuid, classifier, extras["ordinal"] || 0)

        # return filepath
        filepath
    end

    # Librarian::getMikuOrNull(uuid)
    def self.getMikuOrNull(uuid)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return nil if filepath.nil?
        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        FileUtils.rm(filepath)
    end

    # ------------------------------------------------
    # Public Updates
    # ------------------------------------------------

    # Librarian::updateMikuDescription(uuid, description) # Miku
    def self.updateMikuDescription(uuid, description)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::updateMikuDescriptionAtFilepath(filepath, description)
        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::updateMikuDatetime(uuid, datetime)  # Miku
    def self.updateMikuDatetime(uuid, datetime)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::updateMikuDatetimeAtFilepath(filepath, datetime)
        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::updateMikuClassification(uuid, classification)  # Miku
    def self.updateMikuClassification(uuid, classification)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::updateMikuClassificationAtFilepath(filepath, classification)
        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::updateMikuAtom(uuid, atom)  # Miku
    def self.updateMikuAtom(uuid, atom)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::updateMikuAtomAtFilepath(filepath, atom)
        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::updateMikuExtras(uuid, extras)  # Miku
    def self.updateMikuExtras(uuid, extras)
        filepath = Librarian::uuidToFilepathOrNull(uuid)
        return if filepath.nil?
        Librarian::updateMikuExtrasAtFilepath(filepath, extras)
        
        # -----------------------------------------------------------
        miku = Librarian::readMikuObjectFromMikuFileOrError(filepath)
        classifier = miku["classification"]
        ordinal    = extras["ordinal"] || 0
        Librarian::updateIndexFile(uuid, classifier, ordinal)
        # -----------------------------------------------------------

        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # ------------------------------------------------
    # Public Collection Retrieval
    # ------------------------------------------------

    # Librarian::classifierToMikus(classifier)
    def self.classifierToMikus(classifier)
        Librarian::getUUIDsforClassifier(classifier)
            .map{|uuid|
                filepath = Librarian::uuidToFilepathOrNull(uuid)
                if filepath then
                    Librarian::readMikuObjectFromMikuFileOrError(filepath)
                else
                    nil
                end
            }
            .compact
    end

    # Librarian::classifierToMikusLimitByOrdinal(classifier, n)
    def self.classifierToMikusLimitByOrdinal(classifier, n)
        Librarian::getUUIDSForClassifierLimitByOrdinal(classifier, n)
            .map{|uuid|
                filepath = Librarian::uuidToFilepathOrNull(uuid)
                if filepath then
                    Librarian::readMikuObjectFromMikuFileOrError(filepath)
                else
                    nil
                end
            }
            .compact
    end

    # ------------------------------------------------
    # Public Atom Access
    # ------------------------------------------------

    # Librarian::accessMikuAtom(miku) # miku
    def self.accessMikuAtom(miku)
        atom = Atoms5::accessWithOptionToEditOptionalUpdate(miku["atom"])
        if atom then
            Librarian::updateMikuAtom(miku["uuid"], atom)
        end
        Librarian::getMikuOrNull(miku["uuid"])
    end
end
