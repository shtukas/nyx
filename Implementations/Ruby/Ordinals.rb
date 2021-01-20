# encoding: UTF-8

$Ordinals27C16291 = {}

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

    # Ordinals::getOrdinalForUUIDOrNull(uuid)
    def self.getOrdinalForUUIDOrNull(uuid)
        return $Ordinals27C16291[uuid] if $Ordinals27C16291[uuid]
        db = SQLite3::Database.new(Ordinals::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _ordinals_ where _uuid_=?", [uuid] ) do |row|
            answer = row['_ordinal_']
        end
        db.close
        $Ordinals27C16291[uuid] = answer
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
        $Ordinals27C16291[uuid] = ordinal
        nil
    end

    # Ordinals::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        db = SQLite3::Database.new(Ordinals::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _ordinals_ where _uuid_=?", [uuid]
        db.commit 
        db.close
        nil
    end

    # -----------------------------------------------------------------------------

    # Ordinals::getObjectOrdinal(object)
    def self.getObjectOrdinal(object)
        ordinal = Ordinals::getOrdinalForUUIDOrNull(object["uuid"])
        return ordinal if ordinal
        Ordinals::ensureOrdinal(object)
        Ordinals::getOrdinalForUUIDOrNull(object["uuid"])
    end

    # Ordinals::getNextOrdinal()
    def self.getNextOrdinal()
        ([1000] + Ordinals::getOrdinalItems().map{|item| item["ordinal"] }).max + 1
    end

    # -----------------------------------------------------------------------------

    # Ordinals::ensureOrdinal(object)
    def self.ensureOrdinal(object)
        return if Ordinals::getOrdinalForUUIDOrNull(object["uuid"])
        Ordinals::setOrdinalForUUID(object["uuid"], Ordinals::getNextOrdinal())
    end    
end
