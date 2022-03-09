
# encoding: UTF-8

#links2.sqlite3
#create table _links_ (_sourceuuid_ text, _targetuuid_ text, _bidirectional_ integer);
#There isn't a boolean datatype in sqlite, so we use 1 (true) and 0 (false)

class Links2

    # ------------------------------------------------
    # Basic IO

    # Links2::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/links2.sqlite3"
    end

    # Links2::link(sourceuuid, targetuuid, isBidirectional)
    def self.link(sourceuuid, targetuuid, isBidirectional)
        return if (sourceuuid == targetuuid)
        raise "(error: db6b66a4-2ef9-4e14-9adc-f0cf49b91cba, sourceuuid: #{uuid}, targetuuid: #{uuid}, isBidirectional: #{isBidirectional})" if ![0, 1].include?(isBidirectional)
        db = SQLite3::Database.new(Links2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [targetuuid, sourceuuid]
        db.execute "insert into _links_ (_sourceuuid_, _targetuuid_, _bidirectional_) values (?, ?, ?)", [sourceuuid, targetuuid, isBidirectional]
        db.close
    end

    # Links2::unlink(sourceuuid, targetuuid)
    def self.unlink(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Links2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.execute "delete from _links_ where _sourceuuid_=? and _targetuuid_=?", [targetuuid, sourceuuid]
        db.close
    end

    # ------------------------------------------------
    # Relations UUIDs

    # Links2::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)
        db = SQLite3::Database.new(Links2::databaseFilepath())
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

    # Links2::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)
        db = SQLite3::Database.new(Links2::databaseFilepath())
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

    # Links2::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)
        db = SQLite3::Database.new(Links2::databaseFilepath())
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

    # Links2::related(uuid)
    def self.related(uuid)
        Links2::relatedUUIDs(uuid)
            .map{|uuid| Nx31::getOrNull(uuid) }
            .compact
    end

    # Links2::parents(uuid)
    def self.parents(uuid)
        Links2::parentUUIDs(uuid)
            .map{|uuid| Nx31::getOrNull(uuid) }
            .compact
    end

    # Links2::children(uuid)
    def self.children(uuid)
        Links2::childrenUUIDs(uuid)
            .map{|uuid| Nx31::getOrNull(uuid) }
            .compact
    end
end
