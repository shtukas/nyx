
# encoding: UTF-8

=begin

table: links
    _uuid1_    text
    _uuid2_    text

=end

class Links

    # Links::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Links.sqlite3"
    end

    # Links::links()
    def self.links()
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from links" , [] ) do |row|
            answer << {
                "uuid1" => row["_uuid1_"],
                "uuid2" => row["_uuid2_"]
            }
        end
        db.close
        answer
    end

    # ------------------------------------------------
    # Used by ArrowsInMemory

    # Links::issueOrException(alpha, beta)
    def self.issueOrException(alpha, beta)
        raise "[error: f1a60480-7a4e-49a6-9f9f-64ddf9577dd6]" if (alpha["uuid"] == beta["uuid"])
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.execute "delete from links where _uuid1_=? and _uuid2_=?", [alpha["uuid"], beta["uuid"]]
        db.execute "delete from links where _uuid1_=? and _uuid2_=?", [beta["uuid"], alpha["uuid"]]
        db.execute "insert into links (_uuid1_, _uuid2_) values ( ?, ? )", [alpha["uuid"], beta["uuid"]]
        db.close
    end

    # Links::destroy(uuid1, uuid2)
    def self.destroy(uuid1, uuid2)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.execute "delete from links where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
        db.execute "delete from links where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
        db.close
    end

    # Links::unlink(alpha, beta)
    def self.unlink(alpha, beta)
        Links::destroy(alpha["uuid"], beta["uuid"])
    end

    # ------------------------------------------------
    # Below no longer used due to ArrowsInMemory

    # Links::exists?(alpha, beta)
    def self.exists?(alpha, beta)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.results_as_hash = true
        answer = false
        db.execute( "select * from links where _uuid1_=? and _uuid2_=?" , [alpha["uuid"], beta["uuid"]] ) do |row|
            answer = true
        end
        db.execute( "select * from links where _uuid1_=? and _uuid2_=?" , [beta["uuid"], alpha["uuid"]] ) do |row|
            answer = true
        end
        db.close
        answer
    end

    # Links::getLinkedUUIDsForCenter(alpha)
    def self.getLinkedUUIDsForCenter(alpha)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.results_as_hash = true
        uuids = []
        db.execute( "select * from links where _uuid1_=?" , [alpha["uuid"]] ) do |row|
            uuids << row["_uuid2_"]
        end
        db.execute( "select * from links where _uuid2_=?" , [alpha["uuid"]] ) do |row|
            uuids << row["_uuid1_"]
        end
        db.close
        uuids.uniq
    end

    # Links::getLinkedObjectsForCenter(alpha)
    def self.getLinkedObjectsForCenter(alpha)
        Links::getLinkedUUIDsForCenter(alpha)
            .map{|uuid| NyxObjects2::getOrNull(uuid) }
            .compact
    end

    # Links::getLinkedObjectsForCenterOfGivenNyxType(alpha, setid)
    def self.getLinkedObjectsForCenterOfGivenNyxType(alpha, setid)
        Links::getLinkedObjectsForCenter(alpha)
            .select{|object| object["nyxNxSet"] == setid }
    end
end
