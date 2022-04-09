
# encoding: UTF-8

#links2.sqlite3
#create table _links_ (_sourceuuid_ text, _targetuuid_ text, _bidirectional_ integer);
#There isn't a boolean datatype in sqlite, so we use 1 (true) and 0 (false)

class Links

    # ------------------------------------------------
    # Basic IO

    # Links::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/links2.sqlite3"
    end

    # Links::link(sourceuuid, targetuuid, isBidirectional)
    def self.link(sourceuuid, targetuuid, isBidirectional)
        return if (sourceuuid == targetuuid)
        raise "(error: db6b66a4-2ef9-4e14-9adc-f0cf49b91cba, sourceuuid: #{sourceuuid}, targetuuid: #{targetuuid}, isBidirectional: #{isBidirectional})" if ![0, 1].include?(isBidirectional)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [targetuuid, sourceuuid]
        db.execute "insert into _links_ (_sourceuuid_, _targetuuid_, _bidirectional_) values (?, ?, ?)", [sourceuuid, targetuuid, isBidirectional]
        db.close
    end

    # Links::unlink(sourceuuid, targetuuid)
    def self.unlink(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [targetuuid, sourceuuid]
        db.close
    end

    # ------------------------------------------------
    # Relations UUIDs

    # Links::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _links_ where _sourceuuid_=? and _bidirectional_=?" , [uuid, 1] ) do |row|
            answer << row["_targetuuid_"]
        end
        db.execute( "select * from _links_ where _targetuuid_=? and _bidirectional_=?" , [uuid, 2] ) do |row|
            answer << row["_sourceuuid_"]
        end
        db.close
        answer.uniq
    end

    # Links::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _links_ where _targetuuid_=? and _bidirectional_=?" , [uuid, 0] ) do |row|
            answer << row["_sourceuuid_"]
        end
        db.close
        answer.uniq
    end

    # Links::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _links_ where _sourceuuid_=? and _bidirectional_=?" , [uuid, 0] ) do |row|
            answer << row["_targetuuid_"]
        end
        db.close
        answer.uniq
    end

    # ------------------------------------------------
    # Relations Objects

    # Links::related(uuid)
    def self.related(uuid)
        Links::relatedUUIDs(uuid)
            .map{|uuid| Nx31s::getOrNull(uuid) }
            .compact
    end

    # Links::parents(uuid)
    def self.parents(uuid)
        Links::parentUUIDs(uuid)
            .map{|uuid| Nx31s::getOrNull(uuid) }
            .compact
    end

    # Links::children(uuid)
    def self.children(uuid)
        Links::childrenUUIDs(uuid)
            .map{|uuid| Nx31s::getOrNull(uuid) }
            .compact
    end
end
