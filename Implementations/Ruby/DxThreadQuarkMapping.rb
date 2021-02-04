# encoding: UTF-8

class DxThreadQuarkMapping

    # DxThreadQuarkMapping::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/DxThreadQuarkMapping.sqlite3"
    end

    # DxThreadQuarkMapping::insertRecord(dxthread, quark, ordinal)
    def self.insertRecord(dxthread, quark, ordinal)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _mapping_ where _dxthreaduuid_=? and _quarkuuid_=?", [dxthread["uuid"], quark["uuid"]]
        db.execute "insert into _mapping_ (_dxthreaduuid_, _quarkuuid_, _ordinal_) values ( ?, ?, ? )", [dxthread["uuid"], quark["uuid"], ordinal]
        db.commit 
        db.close
        nil
    end

    # DxThreadQuarkMapping::getQuarkUUIDsForDxThreadInOrder(dxthread)
    def self.getQuarkUUIDsForDxThreadInOrder(dxthread)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _mapping_ where _dxthreaduuid_=? order by _ordinal_", [dxthread["uuid"]] ) do |row|
            answer << row['_quarkuuid_']
        end
        db.close
        answer
    end

    # DxThreadQuarkMapping::getDxThreadsForQuark(quark)
    def self.getDxThreadsForQuark(quark)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        dxthreaduuids = []
        db.execute( "select * from _mapping_ where _quarkuuid_=?", [quark["uuid"]] ) do |row|
            dxthreaduuids << row['_dxthreaduuid_']
        end
        db.close
        dxthreaduuids.map{|uuid| TodoCoreData::getOrNull(uuid) }.compact
    end

    # Ordinals

    # DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark)
    def self.getDxThreadQuarkOrdinal(dxthread, quark)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = 0
        db.execute( "select * from _mapping_ where _dxthreaduuid_=? and _quarkuuid_=?", [dxthread["uuid"], quark["uuid"]] ) do |row|
            answer = row['_ordinal_']
        end
        db.close
        answer
    end

    # DxThreadQuarkMapping::setQuarkOrdinal(quark, ordinal)
    def self.setQuarkOrdinal(quark, ordinal)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute( "update _mapping_ set _ordinal_=? where _quarkuuid_=?", [ordinal, quark["uuid"]] )
        db.close
        nil
    end

    # DxThreadQuarkMapping::getQuarkOrdinal(quark)
    def self.getQuarkOrdinal(quark)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = 0
        db.execute( "select * from _mapping_ where _quarkuuid_=?", [quark["uuid"]] ) do |row|
            answer = row['_ordinal_']
        end
        db.close
        answer
    end

    # DxThreadQuarkMapping::getNextOrdinal()
    def self.getNextOrdinal()
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = [0]
        db.execute( "select * from _mapping_", [] ) do |row|
            answer << row['_ordinal_']
        end
        db.close
        answer.max + 1
    end

    # -----------------------------------------------------------------------------

    # DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, cardinal or null)
    def self.dxThreadToQuarksInOrder(dxthread, cardinal = nil)
        quarkuuids = DxThreadQuarkMapping::getQuarkUUIDsForDxThreadInOrder(dxthread)
        if cardinal then
            quarkuuids = quarkuuids.first(cardinal)
        end
        quarkuuids
            .map{|uuid| TodoCoreData::getOrNull(uuid) }
            .compact
    end
end
