
# encoding: UTF-8

class NetworkLocalViews

    # BASIC IO

    # NetworkLocalViews::commitMutation(mutation)
    def self.commitMutation(mutation)
        FileSystemCheck::fsck_MikuTypedItem(mutation, SecureRandom.hex, true)
        filename = "#{CommonUtils::timeStringL22()}.json"
        filepath = "#{Config::pathToDataCenter()}/NetworkLocalViews/mutations/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(mutation)) }
    end

    # NetworkLocalViews::commitLocalViewToDatabase(localView)
    def self.commitLocalViewToDatabase(localView)
        FileSystemCheck::fsck_MikuTypedItem(localView, SecureRandom.hex, true)
        filepath = "#{Config::pathToDataCenter()}/NetworkLocalViews/network-local-views.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _localviews_ where _center_=?", [localView["center"]]
        db.execute "insert into _localviews_ (_center_, _NxNetworkLocalView_) values (?, ?)", [localView["center"], JSON.generate(localView)]
        db.close
    end

    # NetworkLocalViews::getLocalViewFromDatabaseOrNull(center)
    def self.getLocalViewFromDatabaseOrNull(center)
        filepath = "#{Config::pathToDataCenter()}/NetworkLocalViews/network-local-views.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        localView = nil
        db.execute("select * from _localviews_ where _center_=?", [center]) do |row|
            localView = JSON.parse(row["_NxNetworkLocalView_"])
        end
        db.close
        localView
    end

    # NetworkLocalViews::getLocalViewFromDatabaseOrBlank(center)
    def self.getLocalViewFromDatabaseOrBlank(center)
        localView = NetworkLocalViews::getLocalViewFromDatabaseOrNull(center)
        return localView if localView
        {
            "mikuType" => "NxNetworkLocalView",
            "center"   => center,
            "parents"  => [],
            "related"  => [],
            "children" => []
        }
    end

    # NetworkLocalViews::combinator1(nxNetworkLocalView, nxGraphEdge1) # NxNetworkLocalView
    def self.combinator1(nxNetworkLocalView, nxGraphEdge1)
        center = nxNetworkLocalView["center"]
        if nxGraphEdge1["type"] == "bidirectional" then
            if center == nxGraphEdge1["uuid1"] then
                nxNetworkLocalView["related"] = (nxNetworkLocalView["related"] + [nxGraphEdge1["uuid2"]]).uniq
                return nxNetworkLocalView
            end
            if center == nxGraphEdge1["uuid2"] then
                nxNetworkLocalView["related"] = (nxNetworkLocalView["related"] + [nxGraphEdge1["uuid1"]]).uniq
                return nxNetworkLocalView
            end
        end
        if nxGraphEdge1["type"] == "arrow" then
            if center == nxGraphEdge1["uuid1"] then
                nxNetworkLocalView["children"] = (nxNetworkLocalView["children"] + [nxGraphEdge1["uuid2"]]).uniq
                return nxNetworkLocalView
            end
            if center == nxGraphEdge1["uuid2"] then
                nxNetworkLocalView["parents"] = (nxNetworkLocalView["parents"] + [nxGraphEdge1["uuid1"]]).uniq
                return nxNetworkLocalView
            end
        end
        if nxGraphEdge1["type"] == "none" then
            if center == nxGraphEdge1["uuid1"] then
                nxNetworkLocalView["parents"].delete(nxGraphEdge1["uuid2"])
                nxNetworkLocalView["related"].delete(nxGraphEdge1["uuid2"])
                nxNetworkLocalView["children"].delete(nxGraphEdge1["uuid2"])
                return nxNetworkLocalView
            end
            if center == nxGraphEdge1["uuid2"] then
                nxNetworkLocalView["parents"].delete(nxGraphEdge1["uuid1"])
                nxNetworkLocalView["related"].delete(nxGraphEdge1["uuid1"])
                nxNetworkLocalView["children"].delete(nxGraphEdge1["uuid1"])
                return nxNetworkLocalView
            end
        end
        nxNetworkLocalView
    end

    # NetworkLocalViews::mutationsFilepathsOrdered()
    def self.mutationsFilepathsOrdered()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NetworkLocalViews/mutations")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .sort
    end

    # NetworkLocalViews::mutations()
    def self.mutations()
        NetworkLocalViews::mutationsFilepathsOrdered().map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NetworkLocalViews::getLocalViewWithMutations(center)
    def self.getLocalViewWithMutations(center)
        NetworkLocalViews::mutations().reduce(NetworkLocalViews::getLocalViewFromDatabaseOrBlank(center)){|view, mutation|
            NetworkLocalViews::combinator1(view, mutation)
        }
    end

    # SETTERS

    # NetworkLocalViews::relate(uuid1, uuid2)
    def self.relate(uuid1, uuid2)
        NetworkLocalViews::commitMutation({
            "mikuType"    => "NxGraphEdge1",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
            "uuid1"       => uuid1,
            "uuid2"       => uuid2,
            "type"        => "bidirectional" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkLocalViews::arrow(uuid1, uuid2)
    def self.arrow(uuid1, uuid2)
        NetworkLocalViews::commitMutation({
            "mikuType"    => "NxGraphEdge1",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
            "uuid1"       => uuid1,
            "uuid2"       => uuid2,
            "type"        => "arrow" # "bidirectional" | "arrow" | "none"
        })
    end

    # NetworkLocalViews::detach(uuid1, uuid2)
    def self.detach(uuid1, uuid2)
        NetworkLocalViews::commitMutation({
            "mikuType"    => "NxGraphEdge1",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
            "uuid1"       => uuid1,
            "uuid2"       => uuid2,
            "type"        => "none" # "bidirectional" | "arrow" | "none"
        })
    end

    # GETTERS

    # NetworkLocalViews::parentUUIDs(nodeuuid)
    def self.parentUUIDs(nodeuuid)
        NetworkLocalViews::getLocalViewWithMutations(nodeuuid)["parents"]
    end

    # NetworkLocalViews::relatedUUIDs(nodeuuid)
    def self.relatedUUIDs(nodeuuid)
        NetworkLocalViews::getLocalViewWithMutations(nodeuuid)["related"]
    end

    # NetworkLocalViews::childrenUUIDs(nodeuuid)
    def self.childrenUUIDs(nodeuuid)
        NetworkLocalViews::getLocalViewWithMutations(nodeuuid)["children"]
    end

    # NetworkLocalViews::parents(uuid)
    def self.parents(uuid)
        NetworkLocalViews::parentUUIDs(uuid)
            .map{|objectuuid| PolyFunctions::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkLocalViews::relateds(uuid)
    def self.relateds(uuid)
        NetworkLocalViews::relatedUUIDs(uuid)
            .map{|objectuuid| PolyFunctions::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkLocalViews::children(uuid)
    def self.children(uuid)
        NetworkLocalViews::childrenUUIDs(uuid)
            .map{|objectuuid| PolyFunctions::getItemOrNull(objectuuid) }
            .compact
    end

end
