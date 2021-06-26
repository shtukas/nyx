
# encoding: UTF-8

# create table _attributes_ (_uuid_ text, _attributename_ text, _attributevalue_ text);

class Attributes

    # Attributes::databaseFilepath()
    def self.databaseFilepath()
        "#{Utils::catalystDataCenterFolderpath()}/attributes.sqlite3"
    end

    # Attributes::set(uuid, attributename, attributevalue)
    def self.set(uuid, attributename, attributevalue)
        db = SQLite3::Database.new(Attributes::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _attributes_ where _uuid_=? and _attributename_=?", [uuid, attributename]        
        db.execute "insert into _attributes_ (_uuid_, _attributename_ , _attributevalue_) values (?,?,?)", [uuid, attributename, attributevalue]
        db.close
        nil
    end

    # Attributes::getOrNull(uuid, attributename)
    def self.getOrNull(uuid, attributename)
        db = SQLite3::Database.new(Attributes::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _attributes_ where _uuid_=? and _attributename_=?" , [uuid, attributename] ) do |row|
            answer = row["_attributevalue_"]
        end
        db.close
        answer
    end

    # Attributes::getAttributes(uuid)
    def self.getAttributes(uuid)
        db = SQLite3::Database.new(Attributes::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _attributes_ where _uuid_=?" , [uuid] ) do |row|
            answer << {
                "attributename"  => row["_attributename_"],
                "attributevalue" => row["_attributevalue_"]
            }
        end
        db.close
        answer
    end

    # Attributes::getUUIDs(attributename, attributevalue)
    def self.getUUIDs(attributename, attributevalue)
        db = SQLite3::Database.new(Attributes::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _attributes_ where _attributename_=? and _attributevalue_=?" , [uuid, attributename] ) do |row|
            answer << row["_uuid_"]
        end
        db.close
        answer
    end
end