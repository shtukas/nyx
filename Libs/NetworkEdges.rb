
# encoding: UTF-8

class NetworkEdges

    # NetworkEdges::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Instance-Databases/#{Config::get("instanceId")}/network-edges.sqlite3"
    end

    # Getters

    # NetworkEdges::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)
        db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select * from _edges_ where _uuid2_=? and _type_=?", [uuid, "arrow"]) do |row|
            uuids << row["_uuid1_"]
        end
        db.close
        uuids
    end

    # NetworkEdges::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)
        db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select * from _edges_ where _uuid2_=? and _type_=?", [uuid, "bidirectional"]) do |row|
            uuids << row["_uuid1_"]
        end
        db.execute("select * from _edges_ where _uuid1_=? and _type_=?", [uuid, "bidirectional"]) do |row|
            uuids << row["_uuid2_"]
        end
        db.close
        uuids
    end

    # NetworkEdges::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)
        db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        uuids = []
        db.execute("select * from _edges_ where _uuid1_=? and _type_=?", [uuid, "arrow"]) do |row|
            uuids << row["_uuid2_"]
        end
        db.close
        uuids
    end

    # NetworkEdges::parents(uuid)
    def self.parents(uuid)
        NetworkEdges::parentUUIDs(uuid)
            .map{|objectuuid| Phage::getObjectOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::relateds(uuid)
    def self.relateds(uuid)
        NetworkEdges::relatedUUIDs(uuid)
            .map{|objectuuid| Phage::getObjectOrNull(objectuuid) }
            .compact
    end

    # NetworkEdges::children(uuid)
    def self.children(uuid)
        NetworkEdges::childrenUUIDs(uuid)
            .map{|objectuuid| Phage::getObjectOrNull(objectuuid) }
            .compact
    end

    # Changes

    # NetworkEdges::relate(uuid1, uuid2)
    def self.relate(uuid1, uuid2)
        db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
        db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
        db.execute "insert into _edges_ (_uuid1_, _uuid2_, _type_) values (?, ?, ?)", [uuid1, uuid2, "bidirectional"]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "NxGraphEdge1",
            "uuid1"    => uuid1,
            "uuid2"    => uuid2,
            "type"     => "bidirectional" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkEdges::arrow(uuid1, uuid2)
    def self.arrow(uuid1, uuid2)
        db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
        db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
        db.execute "insert into _edges_ (_uuid1_, _uuid2_, _type_) values (?, ?, ?)", [uuid1, uuid2, "arrow"]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "NxGraphEdge1",
            "uuid1"    => uuid1,
            "uuid2"    => uuid2,
            "type"     => "arrow" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkEdges::detach(uuid1, uuid2)
    def self.detach(uuid1, uuid2)
        db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
        db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "NxGraphEdge1",
            "uuid1"    => uuid1,
            "uuid2"    => uuid2,
            "type"     => "none" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkEdges::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "NxGraphEdge1" then

            FileSystemCheck::fsck_NxGraphEdge1(event, SecureRandom.hex, false)

            uuid1 = event["uuid1"]
            uuid2 = event["uuid2"]
            type  = event["type"]

            if type == "arrow" then
                db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
                db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
                db.execute "insert into _edges_ (_uuid1_, _uuid2_, _type_) values (?, ?, ?)", [uuid1, uuid2, "arrow"]
                db.close
            end

            if type == "bidirectional" then
                db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
                db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
                db.execute "insert into _edges_ (_uuid1_, _uuid2_, _type_) values (?, ?, ?)", [uuid1, uuid2, "bidirectional"]
                db.close
            end

            if type == "none" then
                db = SQLite3::Database.new(NetworkEdges::pathToDatabase())
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
                db.execute "delete from _edges_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
                db.close
            end

        end
    end
end
