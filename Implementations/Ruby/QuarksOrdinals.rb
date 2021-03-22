# encoding: UTF-8

class QuarksOrdinals

    # Basic Record Management

    # QuarksOrdinals::databaseFilepath()
    def self.databaseFilepath()
        "#{CatalystUtils::catalystDataCenterFolderpath()}/quarks-ordinals.sqlite3"
    end

    # QuarksOrdinals::setQuarkOrdinal(quark, ordinal)
    def self.setQuarkOrdinal(quark, ordinal)
        db = SQLite3::Database.new(QuarksOrdinals::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _mapping_ where _quarkuuid_=?", [quark["uuid"]]
        db.execute "insert into _mapping_ (_quarkuuid_, _ordinal_) values (?,?,?)", [quark["uuid"], ordinal]
        db.commit 
        db.close
        nil
    end

    # QuarksOrdinals::deleteRecordsByQuarkUUID(uuid)
    def self.deleteRecordsByQuarkUUID(uuid)
        db = SQLite3::Database.new(QuarksOrdinals::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _mapping_ where _quarkuuid_=?", [uuid]
        db.commit 
        db.close
        nil
    end

    # QuarksOrdinals::getQuarkUUIDsInOrdinalOrder()
    def self.getQuarkUUIDsInOrdinalOrder()
        db = SQLite3::Database.new(QuarksOrdinals::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _mapping_ order by _ordinal_", [] ) do |row|
            answer << row['_quarkuuid_']
        end
        db.close
        answer
    end

    # Ordinals

    # QuarksOrdinals::getQuarkOrdinalOrZero(quark)
    def self.getQuarkOrdinalOrZero(quark)
        db = SQLite3::Database.new(QuarksOrdinals::databaseFilepath())
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

    # QuarksOrdinals::getNextOrdinal()
    def self.getNextOrdinal()
        db = SQLite3::Database.new(QuarksOrdinals::databaseFilepath())
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

    # QuarksOrdinals::getOrdinals()
    def self.getOrdinals()
        db = SQLite3::Database.new(QuarksOrdinals::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select _ordinal_ from _mapping_", [] ) do |row|
            answer << row['_ordinal_']
        end
        db.close
        answer
    end

    # -----------------------------------------------------------------------------


    # QuarksOrdinals::dxThreadToFirstNVisibleQuarksInOrdinalOrder(resultSize)
    def self.dxThreadToFirstNVisibleQuarksInOrdinalOrder(resultSize)

        while (uuid = Mercury::dequeueFirstValueOrNullForClient("0437d73d-9cde-4b96-99c5-5bd44671d267", "9298bfca")) do
            QuarksOrdinals::deleteRecordsByQuarkUUID(uuid)
        end

        getMaybeVisibleQuark = lambda {|uuid|
            quark = TodoCoreData::getOrNull(uuid) 
            return nil if quark.nil?
            return nil if !DoNotShowUntil::isVisible(uuid)
            quark
        }

        QuarksOrdinals::getQuarkUUIDsInOrdinalOrder().reduce([]) {|quarks, uuid|
            if quarks.size >= resultSize then
                quarks
            else
                if (quark = getMaybeVisibleQuark.call(uuid)) then
                    quarks + [quark]
                else
                    quarks
                end 
            end
        }
    end
end
