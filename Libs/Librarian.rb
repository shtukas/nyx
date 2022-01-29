
# encoding: UTF-8

require 'sqlite3'

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class Librarian0

    # Librarian0::LibrarianRepositoryFolderpath()
    def self.LibrarianRepositoryFolderpath()
        "/Users/pascal/Galaxy/Librarian"
    end

    # Librarian0::MikuFilesFolderpath()
    def self.MikuFilesFolderpath()
        "#{Librarian0::LibrarianRepositoryFolderpath()}/MikuFiles"
    end

    # Librarian0::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Librarian0::newMikuFilename()
    def self.newMikuFilename()
        "#{Librarian0::timeStringL22()}.miku"
    end

    # Librarian0::classifiers()
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

    # Librarian0::interactivelySelectOneClassifierOrNull()
    def self.interactivelySelectOneClassifierOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("classifier", Librarian0::classifiers())
    end

    # Librarian0::interactivelySelectClassifierOrNull()
    def self.interactivelySelectClassifierOrNull()
        classification = []
        loop {
            type = Librarian0::interactivelySelectOneClassifierOrNull()
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
end

class Librarian1

    # Librarian1::spawnNewMikuFileOrError(uuid, description, datetime, classification, atom) # filepath
    def self.spawnNewMikuFileOrError(uuid, description, datetime, classification, atom)
        # decide filename
        filename = Librarian0::newMikuFilename()

        # decide filepath
        filepath = "#{Librarian0::MikuFilesFolderpath()}/#{filename}"


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

    # Librarian1::readMikuObjectFromMikuFileOrError(filepath)
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

    # Librarian1::commitMikuAtFilepathOrError(miku, filepath)
    def self.commitMikuAtFilepathOrError(miku, filepath)

        # Should error if uuids do not match

        db = SQLite3::Database.new(filepath)

        db.execute "update _table1_ set _data_=? where _name_=?", [miku["description"], "description"]
        db.execute "update _table1_ set _data_=? where _name_=?", [miku["datetime"], "datetime"]
        
        db.execute "delete from _table1_ where _name_=?", ["classification"]
        miku["classification"].each{|classifier|
            db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classifier]
        }

        db.execute "delete from _table1_ where _name_=?", ["atom"]
        db.execute "insert into _table1_ (_name_, _data_) values (?,?)", ["atom", JSON.generate(miku["atom"])]

        db.close
    end

    # Librarian1::interactivelyCreateNewMikuOrNull()
    def self.interactivelyCreateNewMikuOrNull()
        uuid           = SecureRandom.uuid
        description    = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        datetime       = Time.new.utc.iso8601
        classification = Librarian0::interactivelySelectClassifierOrNull()
        atom           = CoreData5::interactivelyCreateNewAtomOrNull()

        filepath = Librarian1::spawnNewMikuFileOrError(uuid, description, datetime, classification, atom)

        Librarian1::readMikuObjectFromMikuFileOrError(filepath)
    end
end

class Librarian2

    # Librarian2::mikufilepaths()
    def self.mikufilepaths()
        [
            "/Users/pascal/Galaxy/Librarian/MikuFiles/20220129-165719-974378.miku"
        ]
    end

    # Librarian2::classifierToFilepaths(classifier)
    def self.classifierToFilepaths(classifier)
        [
            "/Users/pascal/Galaxy/Librarian/MikuFiles/20220129-165719-974378.miku"
        ]
    end

    # Librarian2::classifierToMikus(classifier)
    def self.classifierToMikus(classifier)
        Librarian2::classifierToFilepaths(classifier).map{|filepath|
            Librarian1::readMikuObjectFromMikuFileOrError(filepath)
        }
    end
end