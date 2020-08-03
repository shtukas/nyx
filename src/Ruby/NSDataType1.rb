
# encoding: UTF-8

class NSDataType1

    # NSDataType1::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects::put(object)
        object
    end

    # NSDataType1::objects()
    def self.objects()
        NyxObjects::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType1::toString(node)
    def self.toString(node)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{node["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str
        datalines = NSDataType1::getNodeDatalinesInTimeOrder(node)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(node)
        if description then
            str = "[node] [#{node["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and datalines.size > 0 then
            str = "[node] [#{node["uuid"][0, 4]}] #{NSDataLine::toString(datalines.first)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and datalines.size == 0 then
            str = "[node] [#{node["uuid"][0, 4]}] {no description, no dataline}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        raise "[error: 2b22ddb3-62c4-4940-987a-7a50330dcd36]"
    end

    # NSDataType1::getReferenceUnixtime(ns)
    def self.getReferenceUnixtime(ns)
        DateTime.parse(NSDataType1::getObjectReferenceDateTime(ns)).to_time.to_f
    end

    # NSDataType1::issueDescriptionInteractivelyOrNothing(point)
    def self.issueDescriptionInteractivelyOrNothing(point)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        NSDataTypeXExtended::issueDescriptionForTarget(point, description)
    end

    # NSDataType1::issueNewNodeInteractivelyOrNull()
    def self.issueNewNodeInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == "" 
        node = NSDataType1::issue()
        NSDataTypeXExtended::issueDescriptionForTarget(node, description)
        if LucilleCore::askQuestionAnswerAsBoolean("Create node content frame ? : ") then
            ns0 = NSDataPoint::issueNewPointInteractivelyOrNull()
            if ns0 then
                Arrows::issueOrException(node, ns0)
            end
        end
        node
    end

    # NSDataType1::type1MatchesPattern(point, pattern)
    def self.type1MatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::toString(point).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType1::selectType1sPerPattern(pattern)
    def self.selectType1sPerPattern(pattern)
        NSDataType1::objects()
            .select{|point| NSDataType1::type1MatchesPattern(point, pattern) }
    end

    # NSDataType1::destroyProcedure(point)
    def self.destroyProcedure(point)
        folderpath = DeskOperator::deskFolderpathForNSDataline(point)
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
        NyxObjects::destroy(point)
    end

    # ---------------------------------------------

    # NSDataType1::getObjectDescriptionOrNull(object)
    def self.getObjectDescriptionOrNull(object)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(object)
    end

    # NSDataType1::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        datetime = NSDataTypeXExtended::getLastDateTimeForTargetOrNull(object)
        return datetime if datetime
        Time.at(object["unixtime"]).utc.iso8601
    end

    # NSDataType1::decacheObjectMetadata(node)
    def self.decacheObjectMetadata(node)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{node["uuid"]}") # flush the cached toString
        NSDataType1::getNodeDatalinesInTimeOrder(node).each{|dataline|
            NSDataLine::decacheObjectMetadata(dataline)
        }
    end

    # NSDataType1::landing(node)
    def self.landing(node)

        loop {

            return if NyxObjects::getOrNull(node["uuid"]).nil?
            system("clear")

            NSDataType1::decacheObjectMetadata(node)

            menuitems = LCoreMenuItemsNX1.new()

            # Decache the node

            Miscellaneous::horizontalRule()

            if Miscellaneous::isAlexandra() then
                NSDataType1::getAsteroidsForNode(node).each{|asteroid|
                    menuitems.item(
                        "parent: #{Asteroids::asteroidToString(asteroid)}",
                        lambda { Asteroids::landing(asteroid) }
                    )
                }
            end

            upstream = NSDataType1::getUpstreamNodes(node)
            upstream = NSDataType1::applyDateTimeOrderToType1s(upstream)
            upstream.each{|o|
                menuitems.item(
                    "parent: #{NSDataType1::toString(o)}",
                    lambda { NSDataType1::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            puts "[node]"

            description = NSDataType1::getObjectDescriptionOrNull(node)
            if description then
                puts "    description: #{description}"
            end
            puts "    uuid: #{node["uuid"]}"
            puts "    date: #{NSDataType1::getObjectReferenceDateTime(node)}"

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(node)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
            end

            Miscellaneous::horizontalRule()
            NSDataType1::getNodeDatalinesInTimeOrder(node).each{|dataline|
                NSDataLine::decacheObjectMetadata(dataline)
                ordinal1 = menuitems.ordinal(lambda { NSDataLine::openLastDataPointOrNothing(dataline) })
                ordinal2 = menuitems.ordinal(lambda { NSDataLine::editLastDataPointOrNothing(dataline) })
                puts "[open: #{ordinal1}] [edit: #{ordinal2}] #{NSDataLine::toString(dataline)}"
            }

            ordinal = menuitems.ordinal(lambda {
                dataline = NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
                return if dataline.nil?
                Arrows::issueOrException(node, dataline)
            })
            puts "[ #{ordinal}] issue new dataline"

            Miscellaneous::horizontalRule()

            downstream = NSDataType1::getDownstreamNodes(node)
            downstream = NSDataType1::applyDateTimeOrderToType1s(downstream)
            downstream.each{|o|
                menuitems.item(
                    NSDataType1::toString(o),
                    lambda { NSDataType1::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            description = NSDataType1::getObjectDescriptionOrNull(node)
            if description then
                menuitems.item(
                    "edit description",
                    lambda{
                        description = Miscellaneous::editTextSynchronously(description).strip
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(node, description)
                    }
                )
            else
                menuitems.item(
                    "set description",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(node, description)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "edit reference datetime",
                    lambda{
                        datetime = Miscellaneous::editTextSynchronously(NSDataType1::getObjectReferenceDateTime(node)).strip
                        return if !Miscellaneous::isDateTime_UTC_ISO8601(datetime)
                        NSDataTypeXExtended::issueDateTimeIso8601ForTarget(node, datetime)
                    }
                )
            end


            menuitems.item(
                "edit note",
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(node) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(node, text)
                }
            )


            menuitems.item(
                "attach parent node",
                lambda {
                    n = NSDT1Extended::selectExistingOrMakeNewType1()
                    return if n.nil?
                    Arrows::issueOrException(n, node)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "detach parent node",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", NSDataType1::getUpstreamNodes(node), lambda{|o| NSDataType1::toString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, node)
                    }
                )
            end

            menuitems.item(
                "attach child node (chosen from existing nodes)",
                lambda {
                    o = NSDT1Extended::selectExistingType1InteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(node, o)
                }
            )

            menuitems.item(
                "attach child node (new)",
                lambda {
                    o = NSDataType1::issueNewNodeInteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(node, o)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "detach child node",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", NSDataType1::getDownstreamNodes(node), lambda{|o| NSDataType1::toString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, node)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove [this] as intermediary node", 
                    lambda { 
                        puts "intermediary node removal simulation"
                        NSDataType1::getUpstreamNodes(node).each{|upstreamnode|
                            puts "upstreamnode   : #{NSDataType1::toString(upstreamnode)}"
                        }
                        NSDataType1::getDownstreamNodes(node).each{|downstreampoint|
                            puts "downstreampoint: #{NSDataType1::toString(downstreampoint)}"
                        }
                        return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary node ? ")
                        NSDataType1::getUpstreamNodes(node).each{|upstreamnode|
                            NSDataType1::getDownstreamNodes(node).each{|downstreampoint|
                                Arrows::issueOrException(upstreamnode, downstreampoint)
                            }
                        }
                        NyxObjects::destroy(node)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "select nodes ; move to a new child node",
                    lambda {
                        return if NSDataType1::getDownstreamNodes(node).size == 0

                        # Selecting the nodes
                        selectednodes, _ = LucilleCore::selectZeroOrMore("node", [], NSDataType1::getDownstreamNodes(node), lambda{ |o| NSDataType1::toString(o) })
                        return if selectednodes.size == 0

                        # Selecting or creating the node
                        targetnode = NSDataType1::issueNewNodeInteractivelyOrNull()
                        return if targetnode.nil?

                        # Setting the node as target of this one
                        Arrows::issueOrException(node, targetnode)

                        # Moving the selectednodes
                        selectednodes.each{|o|
                            Arrows::issueOrException(targetnode, o)
                        }
                        selectednodes.each{|o|
                            Arrows::remove(node, o)
                        }
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "select nodes ; move to an existing child node",
                    lambda {
                        return if NSDataType1::getDownstreamNodes(node).size == 0

                        # Selecting the nodes to moves
                        selectednodes, _ = LucilleCore::selectZeroOrMore("node", [], NSDataType1::getDownstreamNodes(node), lambda{ |o| NSDataType1::toString(o) })
                        return if selectednodes.size == 0

                        # Selecting or creating the node
                        possibleTargetNodes = NSDataType1::getDownstreamNodes(object)
                        targetnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", possibleTargetNodes, lambda{|o| NSDataType1::toString(o) })
                        return if targetnode.nil?

                        # Moving the selectednodes
                        selectednodes.each{|o|
                            Arrows::issueOrException(targetnode, o)
                        }
                        selectednodes.each{|o|
                            Arrows::remove(node, o)
                        }
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "destroy [this]",
                    lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this node ? ") then
                            NSDataType1::destroyProcedure(node)
                        end
                    }
                )
            end

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status

        }
    end

    # NSDataType1::getAsteroidsForNode(point)
    def self.getAsteroidsForNode(point)
        Arrows::getSourcesOfGivenSetsForTarget(point, ["b66318f4-2662-4621-a991-a6b966fb4398"])
    end

    # NSDataType1::getUpstreamNodes(object)
    def self.getUpstreamNodes(object)
        Arrows::getSourcesOfGivenSetsForTarget(object, [ "c18e8093-63d6-4072-8827-14f238975d04" ])
    end

    # NSDataType1::getDownstreamNodes(object)
    def self.getDownstreamNodes(object)
        Arrows::getTargetsOfGivenSetsForSource(object, [ "c18e8093-63d6-4072-8827-14f238975d04" ])
    end

    # NSDataType1::applyDateTimeOrderToType1s(objects)
    def self.applyDateTimeOrderToType1s(objects)
        objects
            .map{|object|
                {
                    "object"   => object,
                    "datetime" => NSDataType1::getObjectReferenceDateTime(object)
                }
            }
            .sort{|i1, i2|
                i1["datetime"] <=> i2["datetime"]
            }
            .map{|i| i["object"] }
    end

    # NSDataType1::getNodeDatalinesInTimeOrder(node)
    def self.getNodeDatalinesInTimeOrder(node)
        Arrows::getTargetsOfGivenSetsForSource(node, ["d319513e-1582-4c78-a4c4-bf3d72fb5b2d"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # ---------------------------------------------

    # NSDataType1::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType1::selectType1sPerPattern(pattern)
            .map{|node|
                NSDataType1::decacheObjectMetadata(node)
                node
            }
            .map{|node|
                {
                    "description"   => NSDataType1::toString(node),
                    "referencetime" => NSDataType1::getReferenceUnixtime(node),
                    "dive"          => lambda{ NSDataType1::landing(node) }
                }
            }
    end
end
