
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
        if description then
            typeToDisplayType = lambda {|type|
                return "picture(+)" if type == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1"
                type
            }
            str = "[data] [#{typeToDisplayType.call(datapoints.last["type"])}] #{description}"
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
        Arrows::issueOrException(dataline, ns0)
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
        Arrows::getTargetsForSource(dataline)
            .select{|object| object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataLine::getDatalineLastDataPointOrNull(dataline)
    def self.getDatalineLastDataPointOrNull(dataline)
        NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
            .last
    end

    # NSDataLine::enterLastDataPointOrNothing(dataline)
    def self.enterLastDataPointOrNothing(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?
        puts JSON.pretty_generate(datapoint)
        NSDataPoint::enterDatalineDataPointEnvelop(dataline, datapoint)
    end

    # NSDataType1::datalinePreLandingOperations(dataline)
    def self.datalinePreLandingOperations(dataline)
        cacheKey = "a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}"
        KeyValueStore::destroy(nil, cacheKey)
        NSDataLinePatternSearchLookup::updateLookupForDataline(dataline)
    end

    # NSDataType1::datalinePostUpdateOperations(dataline)
    def self.datalinePostUpdateOperations(dataline)
        cacheKey = "a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}"
        KeyValueStore::destroy(nil, cacheKey)
        NSDataLinePatternSearchLookup::updateLookupForDataline(dataline)
    end

    # NSDataLine::landing(dataline)
    def self.landing(dataline)

        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?

        loop {

            return if NSDataLine::getOrNull(dataline["uuid"]).nil?

            NSDataType1::datalinePreLandingOperations(dataline)

            system('clear')

            menuitems = LCoreMenuItemsNX1.new()

            upstreams = Arrows::getSourcesForTarget(dataline)
            upstreams = GenericObjectInterface::applyDateTimeOrderToObjects(upstreams)
            upstreams.each{|o|
                menuitems.item(
                    "parent: #{GenericObjectInterface::toString(o)}",
                    lambda { GenericObjectInterface::envelop(o) }
                )
            }

            Miscellaneous::horizontalRule()

            puts NSDataLine::toString(dataline)

            puts ""

            menuitems.item(
                "open",
                lambda { NSDataLine::enterLastDataPointOrNothing(dataline) }
            )

            menuitems.item(
                "set/update description",
                lambda {
                    description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(dataline) || ""
                    description = Miscellaneous::editTextSynchronously(description).strip
                    if description != "" then
                        NSDataTypeXExtended::issueDescriptionForTarget(dataline, description)
                    end
                }
            )

            menuitems.item(
                "attach parent node",
                lambda {
                    n = NSDT1ExtendedUserInterface::selectNodeSpecialWeaponsAndTactics()
                    return if n.nil?
                    Arrows::issueOrException(n, node)
                }
            )

            if ["line", "url", "text", "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1", "aion-point"].include?(datapoint["type"]) then
                menuitems.item(
                    "destroy",
                    lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to do that? : ") then
                            NyxObjects2::destroy(dataline)
                        end
                    }
                )
            end

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status
        }

        NSDataType1::datalinePostUpdateOperations(dataline)
    end

    # NSDataLine::getDatalineParents(dataline)
    def self.getDatalineParents(dataline)
        Arrows::getSourcesForTarget(dataline)
    end
end

class NSDataLinePatternSearchLookup

    # NSDataLinePatternSearchLookup::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/NSDataLinesPatternSearchLookup.sqlite3"
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
