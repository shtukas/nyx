# encoding: UTF-8

class DxThreadQuarkMapping

    # DxThreadQuarkMapping::databaseFilepath()
    def self.databaseFilepath()
        "#{CatalystUtils::catalystDataCenterFolderpath()}/DxThreadQuarkMapping.sqlite3"
    end

    # DxThreadQuarkMapping::insertRecord(dxthread, quark, ordinal)
    def self.insertRecord(dxthread, quark, ordinal)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _mapping_ where _dxthreaduuid_=? and _quarkuuid_=?", [dxthread["uuid"], quark["uuid"]]
        db.execute "insert into _mapping_ (_dxthreaduuid_, _quarkuuid_, _ordinal_, _doNotShowUntilUnixtime_) values (?,?,?,?)", [dxthread["uuid"], quark["uuid"], ordinal, 0]
        db.commit 
        db.close
        nil
    end

    # DxThreadQuarkMapping::deleteRecordsByQuarkUUID(uuid)
    def self.deleteRecordsByQuarkUUID(uuid)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _mapping_ where _quarkuuid_=?", [uuid]
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

    # DxThreadQuarkMapping::getVisibleQuarkUUIDsForDxThreadInOrder(dxthread)
    def self.getVisibleQuarkUUIDsForDxThreadInOrder(dxthread)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _mapping_ where _dxthreaduuid_=? and _doNotShowUntilUnixtime_<? order by _ordinal_", [dxthread["uuid"], Time.new.to_i] ) do |row|
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
        db.execute("select * from _mapping_", []) do |row|
            answer << row['_ordinal_']
        end
        db.close
        answer.max + 1
    end

    # DxThreadQuarkMapping::setQuarkDoNotShowUntil(quark, unixtime)
    def self.setQuarkDoNotShowUntil(quark, unixtime)
        db = SQLite3::Database.new(DxThreadQuarkMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute( "update _mapping_ set _doNotShowUntilUnixtime_=? where _quarkuuid_=?", [unixtime, quark["uuid"]] )
        db.close
        nil
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

    # DxThreadQuarkMapping::dxThreadToFirstNVisibleQuarksInOrdinalOrder(dxthread, resultSize)
    def self.dxThreadToFirstNVisibleQuarksInOrdinalOrder(dxthread, resultSize)

        while (message = Mercury::dequeueFirstValueOrNullForClient("e6409074-8123-4914-91ba-da345069609f", "9298bfca")) do
            quark = TodoCoreData::getOrNull(message["uid"])
            next if quark.nil?
            DxThreadQuarkMapping::setQuarkDoNotShowUntil(quark, message["unixtime"])
        end

        while (uuid = Mercury::dequeueFirstValueOrNullForClient("0437d73d-9cde-4b96-99c5-5bd44671d267", "9298bfca")) do
            DxThreadQuarkMapping::deleteRecordsByQuarkUUID(uuid)
        end

        DxThreadQuarkMapping::getVisibleQuarkUUIDsForDxThreadInOrder(dxthread).reduce([]) {|quarks, uuid|
            if quarks.size >= resultSize then
                quarks
            else
                quark = TodoCoreData::getOrNull(uuid)
                if quark then
                    quarks + [quark]
                else
                    quarks
                end 
            end
        }
    end
end
