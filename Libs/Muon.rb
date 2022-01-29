
# encoding: UTF-8

require 'sqlite3'

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class MuonUtilsPrivate

    # MuonUtilsPrivate::databank_muon_folder()
    def self.databank_muon_folder()
        "/Users/pascal/Galaxy/DataBank/Muon"
    end

    # MuonUtilsPrivate::muon_files_folder()
    def self.muon_files_folder()
        "#{MuonUtilsPrivate::databank_muon_folder()}/Files"
    end

    # MuonUtilsPrivate::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # MuonUtilsPrivate::newMuonFilename()
    def self.newMuonFilename()
        "#{MuonUtilsPrivate::timeStringL22()}.muon"
    end

    # MuonUtilsPrivate::classificationTypes()
    def self.classificationTypes()
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

end

class Muon

    # Muon::spawnNewMuonFileOrError(uuid, description, datetime, classification, atom) # filepath
    def self.spawnNewMuonFileOrError(uuid, description, datetime, classification, atom)
        # decide filename
        filename = MuonUtilsPrivate::newMuonFilename()

        # decide filepath
        filepath = "#{MuonUtilsPrivate::muon_files_folder()}/#{filename}"


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

        classification.each{|classificationType|
            db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classificationType]
        }

        db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "atom", JSON.generate(atom)]
        db.close

        # checks

        # return filepath
        filepath
    end

    # Muon::readMuonObjectFromFileOrError(filepath)
    def self.readMuonObjectFromFileOrError(filepath)

        #uuid, description, datetime, classification, atom

        uuid           = nil
        description    = nil
        datetime       = nil
        classification = nil
        atom           = nil

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true

        db.execute("select * from _table1_ where _name_=?", ["uuid"]) do |row|
            uuid = row['_data_']
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
            datetime = JSON.parse(row['_data_'])
        end

        db.close

        {
            "uuid"           => uuid,
            "description"    => description,
            "datetime"       => datetime,
            "classification" => classification,
            "atom"           => atom
        }
    end

    # Muon::commitMuonOrError(muon)
    def self.commitMuonOrError(muon)
        # find the file (should be carried by the muon)
        filepath = muon["filepath"]

        db = SQLite3::Database.new(filepath)

        db.execute "update _table1_ set _data_=? where _name_=?", [muon["description"], "description"]
        db.execute "update _table1_ set _data_=? where _name_=?", [muon["datetime"], "datetime"]
        
        db.execute "delete from _table1_ where _name_=?", ["classification"]
        muon["classification"].each{|classificationType|
            db.execute "insert into _table1_ (_recorduuid_, _unixtime_, _name_, _data_) values (?,?,?,?)", [SecureRandom.uuid, Time.new.to_f, "classification", classificationType]
        }

        db.execute "delete from _attributes_ where _name_=?", ["atom"]
        db.execute "insert into _attributes_ (_name_, _value_) values (?,?)", ["atom", JSON.generate(muon["atom"])]

        db.close
    end

    # Muon::interactivelyCreateNewMuonOrNull()
    def self.interactivelyCreateNewMuonOrNull()
        uuid           = SecureRandom.uuid
        description    = "description"
        datetime       = Time.new.utc.iso8601
        classification = ["TxTest"]
        atom           = CoreData5::issueDescriptionOnlyAtom()

        filepath = Muon::spawnNewMuonFileOrError(uuid, description, datetime, classification, atom)

        Muon::readMuonObjectFromFileOrError(filepath)
    end
end

class MuonCollections

end