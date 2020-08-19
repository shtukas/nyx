
# encoding: UTF-8

=begin

Arrows
{
    "uuid"       : String
    "nyxNxSet"   : "d83a3ff5-023e-482c-8658-f7cfdbb6b738"
    "unixtime"   : Float
    "sourceuuid" : String
    "targetuuid" : String
}

table: arrows
    _sourceuuid_    text
    _targetuuid_    text

=end

class Arrows

    # Arrows::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Arrows.sqlite3"
    end

    # Arrows::issueOrException(source, target)
    def self.issueOrException(source, target)
        raise "[error: bc82b3b6]" if (source["uuid"] == target["uuid"])
        #return if Arrows::exists?(source, target)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.execute "insert into arrows (_sourceuuid_, _targetuuid_) values ( ?, ? )", [source["uuid"], target["uuid"]]
        db.close
    end

    # Arrows::arrows()
    def self.arrows()
        db = SQLite3::Database.new(Arrows::databaseFilepath())
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

    # Arrows::destroy(sourceuuid, targetuuid)
    def self.destroy(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.execute "delete from arrows where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.close
    end

    # Arrows::unlink(source, target)
    def self.unlink(source, target)
        Arrows::destroy(source["uuid"], target["uuid"])
    end

    # Arrows::exists?(source, target)
    def self.exists?(source, target)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.results_as_hash = true
        answer = false
        db.execute( "select * from arrows where _sourceuuid_=? and _targetuuid_=?" , [source["uuid"], target["uuid"]] ) do |row|
            answer = true
        end
        db.close
        answer
    end

    # Arrows::getTargetUUIDsForSource(source)
    def self.getTargetUUIDsForSource(source)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.results_as_hash = true
        uuids = []
        db.execute( "select * from arrows where _sourceuuid_=?" , [source["uuid"]] ) do |row|
            uuids << row["_targetuuid_"]
        end
        db.close
        uuids.uniq
    end

    # Arrows::getTargetsForSource(source)
    def self.getTargetsForSource(source)
        Arrows::getTargetUUIDsForSource(source).map{|uuid| NyxObjects2::getOrNull(uuid) }.compact
    end

    # Arrows::getSourcesForTarget(target)
    def self.getSourcesForTarget(target)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.results_as_hash = true
        uuids = []
        db.execute( "select * from arrows where _targetuuid_=?" , [target["uuid"]] ) do |row|
            uuids << row["_sourceuuid_"]
        end
        db.close
        uuids.uniq.map{|uuid| NyxObjects2::getOrNull(uuid) }.compact
    end
end
