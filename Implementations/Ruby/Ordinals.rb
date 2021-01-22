# encoding: UTF-8

$Ordinals27C16291 = {}

class Ordinals

    # Ordinals::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Ordinals.sqlite3"
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

    # Ordinals::computeNextOrdinal()
    def self.computeNextOrdinal()
        ([0] + Ordinals::getOrdinalItems().map{|item| item["ordinal"] || 0 }).max + 1
    end

    # Ordinals::ensureObjectOrdinal(object)
    def self.ensureObjectOrdinal(object)
        return if Ordinals::getOrdinalForUUIDOrNull(object["uuid"])
        Ordinals::setOrdinalForUUID(object["uuid"], Ordinals::computeNextOrdinal())
    end 

    # Ordinals::getObjectOrdinal(object)
    # If an object doesn't have an ordinal, then the next ordinal is given to it.
    def self.getObjectOrdinal(object)
        ordinal = Ordinals::getOrdinalForUUIDOrNull(object["uuid"])
        return ordinal if ordinal
        ordinal = Ordinals::computeNextOrdinal()
        Ordinals::setOrdinalForUUID(object["uuid"], ordinal)
        ordinal
    end 
end
