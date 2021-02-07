
# encoding: UTF-8

class NyxArrows

    # NyxArrows::issueArrow(sourceuuid, targetuuid)
    def self.issueArrow(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _arrows_ where _source_=? and _target_=?", [sourceuuid, targetuuid]
        db.execute "insert into _arrows_ (_source_, _target_) values (?,?)", [sourceuuid, targetuuid]
        db.commit 
        db.close
    end

    # NyxArrows::deleteArrow(sourceuuid, targetuuid)
    def self.deleteArrow(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _arrows_ where _source_=? and _target_=?", [sourceuuid, targetuuid]
        db.close
    end

    # NyxArrows::getChildrenUUIDs(uuid)
    def self.getChildrenUUIDs(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _arrows_ where _source_=?", [uuid]) do |row|
            answer << row['_target_']
        end
        db.close
        answer
    end

    # NyxArrows::getParentsUUIDs(uuid)
    def self.getParentsUUIDs(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _arrows_ where _target_=?", [uuid]) do |row|
            answer << row['_source_']
        end
        db.close
        answer
    end

    # NyxArrows::removeElementOccurences(uuid)
    def self.removeElementOccurences(uuid)
        db = SQLite3::Database.new(Commons::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _arrows_ where _source_=?", [uuid]
        db.execute "delete from _arrows_ where _target_=?", [uuid]
        db.close
    end
end
