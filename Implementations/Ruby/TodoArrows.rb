
# encoding: UTF-8

=begin

table: arrows
    _sourceuuid_    text
    _targetuuid_    text

=end

class TodoArrows

    # TodoArrows::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Arrows.sqlite3"
    end

    # TodoArrows::arrows()
    def self.arrows()
        db = SQLite3::Database.new(TodoArrows::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from arrows" , [] ) do |row|
            answer << {
                "sourceuuid" => row["_sourceuuid_"],
                "targetuuid" => row["_targetuuid_"]
            }
        end
        db.close
        answer
    end

    # TodoArrows::issueOrException(source, target)
    def self.issueOrException(source, target)
        raise "[error: bc82b3b6]" if (source["uuid"] == target["uuid"])
        db = SQLite3::Database.new(TodoArrows::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from arrows where _sourceuuid_=? and _targetuuid_=?", [source["uuid"], target["uuid"]]
        db.execute "insert into arrows (_sourceuuid_, _targetuuid_) values ( ?, ? )", [source["uuid"], target["uuid"]]
        db.close
    end

    # TodoArrows::destroy(sourceuuid, targetuuid)
    def self.destroy(sourceuuid, targetuuid)
        db = SQLite3::Database.new(TodoArrows::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from arrows where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.close
    end

    # TodoArrows::unlink(source, target)
    def self.unlink(source, target)
        TodoArrows::destroy(source["uuid"], target["uuid"])
    end

    # TodoArrows::exists?(source, target)
    def self.exists?(source, target)
        db = SQLite3::Database.new(TodoArrows::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = false
        db.execute( "select * from arrows where _sourceuuid_=? and _targetuuid_=?" , [source["uuid"], target["uuid"]] ) do |row|
            answer = true
        end
        db.close
        answer
    end

    # TodoArrows::getTargetUUIDsForSource(source)
    def self.getTargetUUIDsForSource(source)
        db = SQLite3::Database.new(TodoArrows::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute( "select * from arrows where _sourceuuid_=?" , [source["uuid"]] ) do |row|
            uuids << row["_targetuuid_"]
        end
        db.close
        uuids.uniq
    end

    # TodoArrows::getSourceUUIDsForTarget(target)
    def self.getSourceUUIDsForTarget(target)
        db = SQLite3::Database.new(TodoArrows::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute( "select * from arrows where _targetuuid_=?" , [target["uuid"]] ) do |row|
            uuids << row["_sourceuuid_"]
        end
        db.close
        uuids.uniq
    end

    # TodoArrows::getTargetsForSource(source)
    def self.getTargetsForSource(source)
        TodoArrows::getTargetUUIDsForSource(source).map{|uuid| TodoCoreData::getOrNull(uuid) }.compact
    end

    # TodoArrows::getSourcesForTarget(target)
    def self.getSourcesForTarget(target)
        TodoArrows::getSourceUUIDsForTarget(target).map{|uuid| TodoCoreData::getOrNull(uuid) }.compact
    end
end
