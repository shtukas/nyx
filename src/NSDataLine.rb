
# encoding: UTF-8

class NSDataLine

    # NSDataLine::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "d319513e-1582-4c78-a4c4-bf3d72fb5b2d",
            "unixtime" => Time.new.to_f,
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataLine::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects2::getOrNull(uuid)
    end

    # NSDataLine::datalines()
    def self.datalines()
        NyxObjects2::getSet("d319513e-1582-4c78-a4c4-bf3d72fb5b2d")
    end

    # NSDataLine::toString(dataline)
    def self.toString(dataline)
        cacheKey = "a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}"
        str = KeyValueStore::getOrNull(nil, cacheKey)
        return str if str
        datapoints = NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(dataline)
        if description and datapoints.size > 0 then
            typeToDisplayType = lambda {|type|
                return "picture(+)" if type == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1"
                type
            }
            str = "[data] [#{typeToDisplayType.call(datapoints.last["type"])}] #{description}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if description and datapoints.size == 0 then
            str = "[data] [no points on the line] #{description}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if description.nil? and datapoints.size > 0 then
            str = "[data] #{NSDataPoint::toStringForDataline(datapoints.last)}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if description.nil? and datapoints.size == 0 then
            str = "{no description, no data}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        raise "[error: 42f8a410-17c4-4130-91b8-bf60c7c10915]"
    end

    # NSDataLine::interactivelyAddNewDataPointToDatalineOrNothing(dataline)
    def self.interactivelyAddNewDataPointToDatalineOrNothing(dataline)
        ns0 = NSDataPoint::issueNewPointInteractivelyOrNull()
        return if ns0.nil?
        $ArrowsInMemory099be9e4.issueOrException(dataline, ns0)
    end

    # NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
    def self.interactiveIssueNewDatalineWithItsFirstPointOrNull()
        dataline = NSDataLine::issue()
        NSDataLine::interactivelyAddNewDataPointToDatalineOrNothing(dataline)
        return nil if NSDataLine::getDatalineDataPointsInTimeOrder(dataline).empty?
        dataline
    end

    # NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
    def self.getDatalineDataPointsInTimeOrder(dataline)
        $ArrowsInMemory099be9e4.getTargetsForSource(dataline)
            .select{|object| object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataLine::getDatalineLastDataPointOrNull(dataline)
    def self.getDatalineLastDataPointOrNull(dataline)
        NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
            .last
    end

    # NSDataLine::accessopen(dataline)
    def self.accessopen(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?
        puts JSON.pretty_generate(datapoint)
        NSDataPoint::enterDatalineDataPointEnvelop(dataline, datapoint)
    end

    # NSDataLine::datalinePreLandingOperations(dataline)
    def self.datalinePreLandingOperations(dataline)
        cacheKey = "a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}"
        KeyValueStore::destroy(nil, cacheKey)
        NSDataLinePatternSearchLookup::updateLookupForDataline(dataline)
    end

    # NSDataLine::datalinePostUpdateOperations(dataline)
    def self.datalinePostUpdateOperations(dataline)
        cacheKey = "a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}"
        KeyValueStore::destroy(nil, cacheKey)
        NSDataLinePatternSearchLookup::updateLookupForDataline(dataline)
    end

    # NSDataLine::landing(dataline)
    def self.landing(dataline)

        loop {

            return if NSDataLine::getOrNull(dataline["uuid"]).nil?

            NSDataLine::datalinePreLandingOperations(dataline)

            system('clear')

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts "[parents]".yellow
            upstreams = $ArrowsInMemory099be9e4.getSourcesForTarget(dataline)
            upstreams = GenericObjectInterface::applyDateTimeOrderToObjects(upstreams)
            upstreams.each{|o|
                menuitems.item(
                    "[parent] #{GenericObjectInterface::toString(o)}",
                    lambda { GenericObjectInterface::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            puts "[dataline]".yellow

            ordinal1 = menuitems.ordinal(lambda{ GenericObjectInterface::accessopen(dataline) })
            ordinal2 = menuitems.ordinal(lambda{ GenericObjectInterface::landing(dataline) })
            puts "[#{ordinal1}: access/open] [#{ordinal2}: landing] #{GenericObjectInterface::toString(dataline)}"

            puts ""

            menuitems.item(
                "set/update description".yellow,
                lambda {
                    description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(dataline) || ""
                    description = Miscellaneous::editTextSynchronously(description).strip
                    if description != "" then
                        NSDataTypeXExtended::issueDescriptionForTarget(dataline, description)
                    end
                }
            )

            menuitems.item(
                "attach parent node".yellow,
                lambda {
                    n = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if n.nil?
                    $ArrowsInMemory099be9e4.issueOrException(n, node)
                }
            )

            menuitems.item(
                "destroy".yellow,
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to do that? : ") then
                        NyxObjects2::destroy(dataline)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.promptAndRunSandbox()
            break if !status
        }

        NSDataLine::datalinePostUpdateOperations(dataline)
    end

    # NSDataLine::getDatalineParents(dataline)
    def self.getDatalineParents(dataline)
        $ArrowsInMemory099be9e4.getSourcesForTarget(dataline)
    end
end

class NSDataLinePatternSearchLookup

    # NSDataLinePatternSearchLookup::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/NSDataLines-Pattern-Search-Lookup.sqlite3"
    end

    # NSDataLinePatternSearchLookup::selectDatalineUUIDsByPattern(pattern)
    def self.selectDatalineUUIDsByPattern(pattern)
        db = SQLite3::Database.new(NSDataLinePatternSearchLookup::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from lookup" , [] ) do |row|
            fragment = row['_fragment_']
            if fragment.downcase.include?(pattern.downcase) then
                answer << row['_objectuuid_']
            end
            
        end
        db.close
        answer.uniq
    end

    # NSDataLinePatternSearchLookup::removeRecordsAgainstDataline(objectuuid)
    def self.removeRecordsAgainstDataline(objectuuid)
        db = SQLite3::Database.new(NSDataLinePatternSearchLookup::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # NSDataLinePatternSearchLookup::addRecord(objectuuid, fragment)
    def self.addRecord(objectuuid, fragment)
        db = SQLite3::Database.new(NSDataLinePatternSearchLookup::databaseFilepath())
        db.execute "insert into lookup (_objectuuid_, _fragment_) values ( ?, ? )", [objectuuid, fragment]
        db.close
    end

    # NSDataLinePatternSearchLookup::updateLookupForDataline(dataline)
    def self.updateLookupForDataline(dataline)
        NSDataLinePatternSearchLookup::removeRecordsAgainstDataline(dataline["uuid"])
        NSDataLinePatternSearchLookup::addRecord(dataline["uuid"], dataline["uuid"])
        NSDataLinePatternSearchLookup::addRecord(dataline["uuid"], NSDataLine::toString(dataline))
    end

    # NSDataLinePatternSearchLookup::rebuildLookup()
    def self.rebuildLookup()
        NSDataLine::datalines()
        .each{|dataline|
            puts dataline["uuid"]
            NSDataLinePatternSearchLookup::updateLookupForDataline(dataline)
        }
    end
end

class NSDataLineExtendedDataLookups

    # NSDataLineExtendedDataLookups::selectDatalinesByPattern(pattern)
    def self.selectDatalinesByPattern(pattern)
        NSDataLinePatternSearchLookup::selectDatalineUUIDsByPattern(pattern)
            .map{|uuid| NSDataLine::getOrNull(uuid) }
            .compact
    end

    # NSDataLineExtendedDataLookups::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataLineExtendedDataLookups::selectDatalinesByPattern(pattern)
            .map{|dataline|
                {
                    "description"   => NSDataLine::toString(dataline),
                    "referencetime" => dataline["unixtime"],
                    "dive"          => lambda{ NSDataLine::landing(dataline) }
                }
            }
    end
end
