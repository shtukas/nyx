
# encoding: UTF-8

class NxDataCarrier

    # NxDataCarrier::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx10s.sqlite3"
    end

    # NxDataCarrier::insertNewNx10(uuid, datetime, description, taxonomy, contentType, contentPayload)
    def self.insertNewNx10(uuid, datetime, description, taxonomy, contentType, contentPayload)
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx10s_ (_uuid_, _datetime_, _description_, _taxonomy_, _contentType_, _contentPayload_) values (?,?,?,?,?,?)", [uuid, datetime, description, taxonomy, contentType, contentPayload]
        db.close
    end

    # NxDataCarrier::destroyNx10(uuid)
    def self.destroyNx10(uuid)
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx10s_ where _uuid_=?", [uuid]
        db.close
    end

    # NxDataCarrier::databaseRowToDataObject(row)
    def self.databaseRowToDataObject(row)
        obj = {
            "uuid"        => row["_uuid_"],
            "entityType"  => "Nx10",
            "datetime"    => row["_datetime_"],
            "description" => row["_description_"],
            "taxonomy"    => row["_taxonomy_"],
            "contentType"    => row["_contentType_"],
            "contentPayload" => row["_contentPayload_"]
        }
        if !EntityTaxonomy::taxonomies().include?(obj["taxonomy"]) then
            obj["taxonomy"] = "TxUndefined"
        end
        obj
    end

    # NxDataCarrier::getNx10ByIdOrNull(id): null or Nx10
    def self.getNx10ByIdOrNull(id)
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx10s_ where _uuid_=?" , [id] ) do |row|
            answer = NxDataCarrier::databaseRowToDataObject(row)
        end
        db.close
        answer
    end

    # NxDataCarrier::interactivelyCreateNewNx10OrNull()
    def self.interactivelyCreateNewNx10OrNull()
        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        contentCoordinates = Axion::interactivelyIssueNewCoordinatesOrNull()
        return nil if contentCoordinates.nil?

        taxonomy = EntityTaxonomy::selectEntityTaxonomyOrNull()
        return if taxonomy.nil?

        NxDataCarrier::insertNewNx10(uuid, Time.new.utc.iso8601, description, taxonomy, contentCoordinates["contentType"], contentCoordinates["contentPayload"])
        NxDataCarrier::getNx10ByIdOrNull(uuid)
    end

    # NxDataCarrier::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxDataCarrier::updateEntityTaxonomy(uuid, taxonomy)
    def self.updateEntityTaxonomy(uuid, taxonomy)
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _taxonomy_=? where _uuid_=?", [taxonomy, uuid]
        db.close
    end

    # NxDataCarrier::updateNx10Content(uuid, contentType, contentPayload)
    def self.updateNx10Content(uuid, contentType, contentPayload)
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _contentType_=?, _contentPayload_=?  where _uuid_=?", [contentType, contentPayload, uuid]
        db.close
    end

    # NxDataCarrier::nx10s(): Array[Nx10]
    def self.nx10s()
        db = SQLite3::Database.new(NxDataCarrier::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx10s_" , [] ) do |row|
            answer << NxDataCarrier::databaseRowToDataObject(row)
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxDataCarrier::toString(nx10)
    def self.toString(nx10)
        "[node] #{nx10["description"]}"
    end

    # NxDataCarrier::selectOneNx10OrNull()
    def self.selectOneNx10OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxDataCarrier::nx10s(), lambda{|nx10| NxDataCarrier::toString(nx10) })
    end

    # NxDataCarrier::architectOneNx10OrNull()
    def self.architectOneNx10OrNull()
        nx10 = NxDataCarrier::selectOneNx10OrNull()
        return nx10 if nx10
        NxDataCarrier::interactivelyCreateNewNx10OrNull()
    end

    # NxDataCarrier::landing(nx10)
    def self.landing(nx10)
        loop {
            nx10 = NxDataCarrier::getNx10ByIdOrNull(nx10["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx10.nil?
            system("clear")

            puts NxDataCarrier::toString(nx10).green
            puts "uuid: #{nx10["uuid"]}".yellow
            puts "taxonomy: #{nx10["taxonomy"]}".yellow
            puts ""

            entities = Links::entities(nx10["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NyxEntities::toString(entity)}" }

            puts ""

            puts "access | update description | update taxonomy | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NyxEntities::landing(entity)
            end

            if Interpreting::match("access", command) then
                contentType    = nx10["contentType"]
                contentPayload = nx10["contentPayload"]
                Axion::access(contentType, contentPayload, nil)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx10["description"]).strip
                return if description == ""
                NxDataCarrier::updateDescription(nx10["uuid"], description)
            end

            if Interpreting::match("update taxonomy", command) then
                taxonomy = EntityTaxonomy::selectEntityTaxonomyOrNull()
                return if taxonomy.nil?
                NxDataCarrier::updateEntityTaxonomy(nx10["uuid"], taxonomy)
            end

            if Interpreting::match("connect", command) then
                NyxEntities::linkToOtherArchitectured(nx10)
            end

            if Interpreting::match("disconnect", command) then
                NyxEntities::unlinkFromOther(nx10)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxDataCarrier::destroyNx10(nx10["uuid"])
                end
            end
        }
    end

    # NxDataCarrier::nx19s()
    def self.nx19s()
        NxDataCarrier::nx10s().map{|nx10|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxDataCarrier::toString(nx10)}",
                "type"     => "Nx10",
                "payload"  => nx10
            }
        }
    end
end
