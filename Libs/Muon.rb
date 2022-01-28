
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

    # MuonUtilsPrivate::spawnNewMuonFileOrNothing(uuid, description, datetime, classification, atom) # filepath
    def self.spawnNewMuonFileOrNothing(uuid, description, datetime, classification, atom)
        # decide filename
        filename = MuonUtilsPrivate::newMuonFilename()

        # decide filepath
        filepath = "#{MuonUtilsPrivate::muon_files_folder()}/#{filename}"


        # create file
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "create table _attributes_ (_key_ string primary key, _value_ text)", []
        db.execute "create table _sets_ (_recorduuid_ text primary key, _name_ string, _value_ text)", []
        db.execute "create table _datablobs_ (_key_ string primary key, _data_ blob)", []
        db.close

        # commit information
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }

        db.execute "insert into _attributes_ (_key_, _value_) values (?,?)", ["muon:version", "20220128"]
        db.execute "insert into _attributes_ (_key_, _value_) values (?,?)", ["muon:uuid", uuid]
        db.execute "insert into _attributes_ (_key_, _value_) values (?,?)", ["muon:description", description]
        db.execute "insert into _attributes_ (_key_, _value_) values (?,?)", ["muon:datetime", datetime]

        classification.each{|classificationType|
            recorduuid = SecureRandom.uuid
            db.execute "insert into _sets_ (_recorduuid_, _name_, _value_) values (?,?,?)", [recorduuid, "muon:classification", classificationType]
        }

        db.execute "insert into _attributes_ (_key_, _value_) values (?,?)", ["muon:atom", JSON.generate(atom)]
        db.close

        # checks

        # return filepath
        filepath
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
            "PascalPrivateLog"
        ]
    end

end

class MuonFileOpsInterface

    # MuonFileOpsInterface::classificationTypes()
    def self.classificationTypes()
        MuonUtilsPrivate::classificationTypes()
    end

    # MuonFileOpsInterface::spawnNewMuonFileOrNothing(uuid, description, datetime, classification, atom) # filepath
    def self.spawnNewMuonFileOrNothing(uuid, description, datetime, classification, atom)
        MuonUtilsPrivate::spawnNewMuonFileOrNothing(uuid, description, datetime, classification, atom)
    end
end

class MuonCollections

end