
# encoding: UTF-8

class NodeTaxonomy

    # NodeTaxonomy::taxonomys()
    def self.taxonomys()
        [
            "NxUndefined",
            "NxPersonalDiary",
            "NxPersonalCalendar",
            "NxPersonalEvent",
            "NxTravelAndEntertainmentDocuments",
            "NxPublicEvent",
            "NxInformation",
            "NxExplanation",
            "NxFunny"
        ]
    end

    # NodeTaxonomy::selectNodeTaxonomyOrNull()
    def self.selectNodeTaxonomyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node taxonomy:", NodeTaxonomy::taxonomys())
    end
end

class NxNode

    # NxNode::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx10s.sqlite3"
    end

    # NxNode::insertNewNx10(uuid, datetime, description, taxonomy, axionuuid)
    def self.insertNewNx10(uuid, datetime, description, taxonomy, axionuuid)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx10s_ (_uuid_, _datetime_, _description_, _taxonomy_, _axionuuid_) values (?,?,?,?,?)", [uuid, datetime, description, taxonomy, axionuuid]
        db.close
    end

    # NxNode::destroyNx10(uuid)
    def self.destroyNx10(uuid)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx10s_ where _uuid_=?", [uuid]
        db.close
    end

    # NxNode::getNx10ByIdOrNull(id): null or Nx10
    def self.getNx10ByIdOrNull(id)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx10s_ where _uuid_=?" , [id] ) do |row|
            obj = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
                "taxonomy"    => row["_taxonomy_"],
                "axionuuid"   => row["_axionuuid_"]
            }
            if !NodeTaxonomy::taxonomys().include?(obj["taxonomy"]) then
                obj["taxonomy"] = "NxUndefined"
            end
            answer = obj
        end
        db.close
        answer
    end

    # NxNode::interactivelyCreateNewNx10OrNull()
    def self.interactivelyCreateNewNx10OrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        taxonomy = NodeTaxonomy::selectNodeTaxonomyOrNull()
        return if taxonomy.nil?
        NxNode::insertNewNx10(uuid, Time.new.utc.iso8601, description, taxonomy, nil)
        NxNode::getNx10ByIdOrNull(uuid)
    end

    # NxNode::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxNode::updateNodeTaxonomy(uuid, taxonomy)
    def self.updateNodeTaxonomy(uuid, taxonomy)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _taxonomy_=? where _uuid_=?", [taxonomy, uuid]
        db.close
    end

    # NxNode::updateNodeAxionUUID(uuid, axionuuid)
    def self.updateNodeTaxonomy(uuid, axionuuid)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _axionuuid_=? where _uuid_=?", [axionuuid, uuid]
        db.close
    end

    # NxNode::nx10s(): Array[Nx10]
    def self.nx10s()
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx10s_" , [] ) do |row|
            obj = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
                "taxonomy"    => row["_taxonomy_"],
                "axionuuid"   => row["_axionuuid_"]
            }
            if !NodeTaxonomy::taxonomys().include?(obj["taxonomy"]) then
                obj["taxonomy"] = "NxUndefined"
            end
            answer << obj
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxNode::toString(nx10)
    def self.toString(nx10)
        "[node] #{nx10["description"]}"
    end

    # NxNode::selectOneNx10OrNull()
    def self.selectOneNx10OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxNode::nx10s(), lambda{|nx10| NxNode::toString(nx10) })
    end

    # NxNode::architectOneNx10OrNull()
    def self.architectOneNx10OrNull()
        nx10 = NxNode::selectOneNx10OrNull()
        return nx10 if nx10
        NxNode::interactivelyCreateNewNx10OrNull()
    end

    # NxNode::landing(nx10)
    def self.landing(nx10)
        loop {
            nx10 = NxNode::getNx10ByIdOrNull(nx10["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx10.nil?
            system("clear")

            puts NxNode::toString(nx10).green
            puts "uuid: #{nx10["uuid"]}".yellow
            puts "node taxonomy: #{nx10["taxonomy"]}".yellow
            puts ""

            entities = Links::entities(nx10["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "update description | update node taxonomy | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx10["description"]).strip
                return if description == ""
                NxNode::updateDescription(nx10["uuid"], description)
            end

            if Interpreting::match("update node taxonomy", command) then
                taxonomy = NodeTaxonomy::selectNodeTaxonomyOrNull()
                return if taxonomy.nil?
                NxNode::updateNodeTaxonomy(nx10["uuid"], taxonomy)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx10)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx10)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxNode::destroyNx10(nx10["uuid"])
                end
            end
        }
    end

    # NxNode::nx19s()
    def self.nx19s()
        NxNode::nx10s().map{|nx10|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxNode::toString(nx10)}",
                "type"     => "Nx10",
                "payload"  => nx10
            }
        }
    end
end
