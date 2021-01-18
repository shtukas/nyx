# encoding: UTF-8

class Ordinals

    # Ordinals::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Ordinals.sqlite3"
    end

    # Ordinals::getOrdinalItems()
    def self.getOrdinalItems()
        db = SQLite3::Database.new(Ordinals::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        items = []
        db.execute( "select * from _ordinals_", [] ) do |row|
            items << {
                "uuid"    => row['_uuid_'],
                "ordinal" => row['_ordinal_']
            }
        end
        db.close
        items
    end

    # Ordinals::getOrdinalForUUID(uuid)
    def self.getOrdinalForUUID(uuid)
        db = SQLite3::Database.new(Ordinals::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _ordinals_ where _uuid_=?", [uuid] ) do |row|
            answer = row['_ordinal_']
        end
        db.close
        answer
    end

    # Ordinals::setOrdinalForUUID(uuid, ordinal)
    def self.setOrdinalForUUID(uuid, ordinal)
        db = SQLite3::Database.new(Ordinals::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _ordinals_ where _uuid_=?", [uuid]
        db.execute "insert into _ordinals_ (_uuid_, _ordinal_) values ( ?, ? )", [uuid, ordinal]
        db.commit 
        db.close
        nil
    end

    # -----------------------------------------------------------------------------

    # Ordinals::getNextLowOrdinal()
    def self.getNextLowOrdinal()
        ordinal = ([0] + Ordinals::getOrdinalItems().map{|item| item["ordinal"] }.select{|ordinal| ordinal < 1000 }).max
        if ordinal < 500 then
            return ordinal + 1
        end
        (ordinal + 1000).to_f/2
    end

    # Ordinals::getNextHighOrdinal()
    def self.getNextHighOrdinal()
        ([1000] + Ordinals::getOrdinalItems().map{|item| item["ordinal"] }).max + 1
    end

    # -----------------------------------------------------------------------------

    # Ordinals::ensureLowOrdinal(object)
    def self.ensureLowOrdinal(object)
        return if Ordinals::getOrdinalForUUID(object["uuid"])
        Ordinals::setOrdinalForUUID(object["uuid"], Ordinals::getNextLowOrdinal())
    end

    # Ordinals::ensureHighOrdinal(object)
    def self.ensureHighOrdinal(object)
        return if Ordinals::getOrdinalForUUID(object["uuid"])
        Ordinals::setOrdinalForUUID(object["uuid"], Ordinals::getNextHighOrdinal())
    end    
end
