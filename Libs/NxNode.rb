
# encoding: UTF-8

class NxNode

    # NxNode::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nxnodes.sqlite3"
    end

    # NxNode::insertNewNxNode(uuid, datetime, denomination)
    def self.insertNewNxNode(uuid, datetime, denomination)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nxnodes_ (_uuid_, _datetime_, _denomination_) values (?,?,?)", [uuid, datetime, denomination]
        db.close
    end

    # NxNode::destroyNxNode(uuid)
    def self.destroyNxNode(uuid)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nxnodes_ where _uuid_=?", [uuid]
        db.close
    end

    # NxNode::tableHashRowToNxNode(row)
    def self.tableHashRowToNxNode(row)
        return {
            "uuid"         => row["_uuid_"],
            "entityType"   => "NxNode",
            "datetime"     => row["_datetime_"],
            "taxonomy"     => "TxNode",
            "denomination" => row["_denomination_"],
        }
    end

    # NxNode::getNxNodeByIdOrNull(uuid): null or NxNode
    def self.getNxNodeByIdOrNull(uuid)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nxnodes_ where _uuid_=?" , [uuid] ) do |row|
            answer = NxNode::tableHashRowToNxNode(row)
        end
        db.close
        answer
    end

    # NxNode::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid
        denomination = LucilleCore::askQuestionAnswerAsString("denomination (empty to abort): ")
        return nil if denomination == ""
        NxNode::insertNewNxNode(uuid, Time.new.utc.iso8601, denomination)
        NxNode::getNxNodeByIdOrNull(uuid)
    end

    # NxNode::nxnodes(): Array[NxNode]
    def self.nxnodes()
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nxnodes_" , [] ) do |row|
            answer << NxNode::tableHashRowToNxNode(row)
        end
        db.close
        answer
    end

    # NxNode::updateDenomination(uuid, denomination)
    def self.updateDenomination(uuid, denomination)
        db = SQLite3::Database.new(NxNode::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nxnodes_ set _denomination_=? where _uuid_=?", [denomination, uuid]
        db.close
    end

    # ----------------------------------------------------------------------

    # NxNode::toString(nxnode)
    def self.toString(nxnode)
        "[node] #{nxnode["denomination"]}"
    end

    # NxNode::access(nxnode)
    def self.access(nxnode)
        puts NxNode::toString(nxnode)
        LucilleCore::pressEnterToContinue()
    end

    # NxNode::landing(nxnode)
    def self.landing(nxnode)
        loop {
            nxnode = NxNode::getNxNodeByIdOrNull(nxnode["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxnode.nil?
            system("clear")

            puts NxNode::toString(nxnode).green
            puts "taxonomy: #{nxnode["taxonomy"]}".yellow
            puts ""

            entities = Links::entities(nxnode["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NyxEntities::toString(entity)}" }

            puts ""

            puts "access | update denomination | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NyxEntities::landing(entity)
            end

            if Interpreting::match("access", command) then
                NxNode::access(nxnode)
            end

            if Interpreting::match("update denomination", command) then
                denomination = Utils::editTextSynchronously(nxnode["denomination"]).strip
                return if denomination == ""
                NxNode::updateDenomination(nxnode["uuid"], denomination)
            end

            if Interpreting::match("connect", command) then
                NyxEntitieslinkToOtherArchitectured(nxnode)
            end

            if Interpreting::match("disconnect", command) then
                NyxEntitiesunlinkFromOther(nxnode)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    NxNode::destroyNxNode(nxnode["uuid"])
                end
            end
        }
    end

    # NxNode::nx19s()
    def self.nx19s()
        NxNode::nxnodes().map{|nxnode|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxNode::toString(nxnode)}",
                "type"     => "NxNode",
                "payload"  => nxnode
            }
        }
    end
end
