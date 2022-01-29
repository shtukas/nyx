
# encoding: UTF-8

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

    # Librarian::interactivelySelectOneClassifierOrNull()
    def self.interactivelySelectOneClassifierOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("classifier", Librarian::classifiers())
    end

    # Librarian::interactivelySelectClassifierOrNull()
    def self.interactivelySelectClassifierOrNull()
        classification = []
        loop {
            type = Librarian::interactivelySelectOneClassifierOrNull()
            if type.nil? and classification.empty? then
                next
            end
            break if type.nil?
            classification << type
            classification = classification.uniq
            puts ""
            puts "currently selected: #{classification.join(", ")}"
        }
        classification
    end

    # Librarian::readMikuObjectFromMikuFileOrError(filepath)
    def self.readMikuObjectFromMikuFileOrError(filepath)

        uuid           = nil
        version        = nil
        description    = nil
        datetime       = nil
        classification = nil
        atom           = nil
        notes          = nil

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
        db.execute("select * from _table1_ where _name_=?", ["datetime"]) do |row|
            datetime = row['_data_']
        end

        classification = []
        db.execute("select * from _table1_ where _name_=?", ["classification"]) do |row|
            classification << row['_data_']
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

        db.close

        {
            "uuid"           => uuid,
            "version"        => version,
            "description"    => description,
            "datetime"       => datetime,
            "classification" => classification,
            "atom"           => atom,
            "notes"          => notes
        }
    end

    # Librarian::interactivelyCreateNewMikuOrNull()
    def self.interactivelyCreateNewMikuOrNull()
        uuid           = SecureRandom.uuid
        description    = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        datetime       = Time.new.utc.iso8601
        classification = Librarian::interactivelySelectClassifierOrNull()
        atom           = CoreData5::interactivelyCreateNewAtomOrNull()

        filepath = Librarian::spawnNewMikuFileOrError(uuid, description, datetime, classification, atom)

        Librarian::readMikuObjectFromMikuFileOrError(filepath)
    end

    # Librarian::mikufilepaths()
    def self.mikufilepaths()
        [
            "/Users/pascal/Galaxy/Librarian/MikuFiles/20220129-165719-974378.miku"
        ]
    end

    # Librarian::classifierToFilepaths(classifier)
    def self.classifierToFilepaths(classifier)
        [
            "/Users/pascal/Galaxy/Librarian/MikuFiles/20220129-165719-974378.miku"
        ]
    end

    # Librarian::uuidToFilepathOrNull(uuid)
    def self.uuidToFilepathOrNull(uuid)
        raise "6629c6f9-3667-4ee5-8e74-af20c25cb2b6" if uuid != "686b4e1b-6128-47c9-8f87-c391d2b395f2"
        "/Users/pascal/Galaxy/Librarian/MikuFiles/20220129-165719-974378.miku"
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
        db.execute "delete from _table1_ where _name_=?", ["classification"]
        classification.each{|classifier|
            db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classifier]
        }
        db.close
    end

    # Librarian::updateMikuAtomAtFilepath(filepath, atom)
    def self.updateMikuAtomAtFilepath(filepath, atom)
        db = SQLite3::Database.new(filepath)
        db.execute "update _table1_ set _data_=? where _name_=?", [JSON.generate(atom), "atom"]
        db.close
    end

    # ------------------------------------------------
    # Public Creation
    # ------------------------------------------------

    # Librarian::spawnNewMikuFileOrError(uuid, description, datetime, classification, atom) # filepath
    def self.spawnNewMikuFileOrError(uuid, description, datetime, classification, atom)
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

        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "version", "20220128"]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "uuid", uuid]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "description", description]
        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "datetime", datetime]

        classification.each{|classifier|
            db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classifier]
        }

        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "atom", JSON.generate(atom)]
        db.close

        # checks

        # return filepath
        filepath
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

    # ------------------------------------------------
    # Public Collection Retrieval
    # ------------------------------------------------

    # Librarian::classifierToMikus(classifier)
    def self.classifierToMikus(classifier)
        Librarian::classifierToFilepaths(classifier).map{|filepath|
            Librarian::readMikuObjectFromMikuFileOrError(filepath)
        }
    end
end