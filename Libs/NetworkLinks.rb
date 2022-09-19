
# encoding: UTF-8

class NetworkLinks

    # NetworkLinks::databaseFile()
    def self.databaseFile()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate/network-links.sqlite3"
    end

    # NetworkLinks::insertRow(row)
    def self.insertRow(row)
        $links_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkLinks::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _links_ where _eventuuid_=?", [row["_eventuuid_"]]
            db.execute "insert into _links_ (_eventuuid_, _eventTime_, _sourceuuid_, _operation_, _targetuuid_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_eventTime_"], row["_sourceuuid_"], row["_operation_"], row["_targetuuid_"]]
            db.close
        }
    end

    # NetworkLinks::issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
    def self.issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
        raise "(error: 1afe537d-edae-4f87-9615-042b9c43cd05)" if sourceuuid.nil?
        if !["link", "unlink"].include?(operation) then
            raise "(error: 535c3cf7-f93b-43b2-8530-eb892910ceda) operation: #{operation}"
        end
        raise "(error: 9ee4dae9-1fee-4ba7-9016-80e56e58aa08)" if targetuuid.nil?
        $links_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkLinks::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "insert into _links_ (_eventuuid_, _eventTime_, _sourceuuid_, _operation_, _targetuuid_) values (?, ?, ?, ?, ?)", [eventuuid, eventTime, sourceuuid, operation, targetuuid]
            db.close
        }
    end

    # NetworkLinks::issue(sourceuuid, operation, targetuuid)
    def self.issue(sourceuuid, operation, targetuuid)
        if !["link", "unlink"].include?(operation) then
            raise "(error: cf4cb260-1709-474d-a4f9-3f99f95fdb52) operation: #{operation}"
        end
        eventuuid = SecureRandom.uuid
        eventTime = Time.new.to_f
        NetworkLinks::issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
        SystemEvents::broadcast({
          "mikuType"   => "NetworkLinks",
          "eventuuid"  => eventuuid,
          "eventTime"  => eventTime,
          "sourceuuid" => sourceuuid,
          "operation"  => operation,
          "targetuuid" => targetuuid
        })
    end

    # NetworkLinks::link(uuid1, uuid2)
    def self.link(uuid1, uuid2)
        NetworkLinks::issue(uuid1, "link", uuid2)
        NetworkLinks::issue(uuid2, "link", uuid1)
    end

    # NetworkLinks::unlink(uuid1, uuid2)
    def self.unlink(uuid1, uuid2)
        NetworkLinks::issue(uuid1, "unlink", uuid2)
        NetworkLinks::issue(uuid2, "unlink", uuid1)
    end

    # NetworkLinks::linkeduuids(itemuuid)
    def self.linkeduuids(itemuuid)
        linkeduuids = []
        $links_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkLinks::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _links_ where _sourceuuid_=? order by _eventTime_", [itemuuid]) do |row|
                if row["_operation_"] == "link" then
                    linkeduuids = (linkeduuids + [row["_targetuuid_"]]).uniq
                end
                if row["_operation_"] == "unlink" then
                    linkeduuids = linkeduuids - [row["_targetuuid_"]]
                end
            end
            db.close
        }
        linkeduuids.compact
    end

    # NetworkLinks::eventuuids()
    def self.eventuuids()
        answer = []
        $links_database_semaphore.synchronize {
            db = SQLite3::Database.new(NetworkLinks::databaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select _eventuuid_ from _links_", []) do |row|
                answer << row["_eventuuid_"]
            end
            db.close
        }
        answer
    end

    # NetworkLinks::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "NetworkLinks" then
            eventuuid  = event["eventuuid"]
            eventTime  = event["eventTime"] || Time.new.to_f
            sourceuuid = event["sourceuuid"]
            operation  = event["operation"]
            targetuuid = event["targetuuid"]
            NetworkLinks::issueNoEvents(eventuuid, eventTime, sourceuuid, operation, targetuuid)
        end
    end

    # NetworkLinks::linkedEntities(uuid)
    def self.linkedEntities(uuid)
        NetworkLinks::linkeduuids(uuid)
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end

    # NetworkLinks::interactivelySelectLinkedEntityOrNull(uuid)
    def self.interactivelySelectLinkedEntityOrNull(uuid)
        entities = NetworkLinks::linkedEntities(uuid).sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("entity", entities, lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkLinks::interactivelySelectLinkedEntities(uuid)
    def self.interactivelySelectLinkedEntities(uuid)
        entities = NetworkLinks::linkedEntities(uuid).sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("entity", [], entities, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # NetworkLinks::architectureAndLink(item)
    def self.architectureAndLink(item)
        item2 = Nyx::architectOneOrNull()
        return if item2.nil?
        NetworkLinks::link(item["uuid"], item2["uuid"])
    end

    # NetworkLinks::selectOneLinkedAndUnlink(item)
    def self.selectOneLinkedAndUnlink(item)
        store = ItemStore.new()

        NetworkLinks::linkeduuids(item["uuid"]) # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entityuuid|
                entity = Items::getItemOrNull(entityuuid)
                next if entity.nil?
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NetworkLinks::unlink(item["uuid"], entity["uuid"])
        end
    end
end
