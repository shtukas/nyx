
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

    # NSDataType1::toString(point)
    def self.toString(point)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{point["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        ns0s = NSDataType1::getFramesInTimeOrder(point)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(point)
        if description then
            str = "[node] [#{point["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size > 0 then
            str = "[node] [#{point["uuid"][0, 4]}] #{NSDataType0s::frameToString(ns0s.last)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size == 0 then
            str = "[node] [#{point["uuid"][0, 4]}] {no description, no frame}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        "[node] [#{point["uuid"][0, 4]}] [error: 752a3db2 ; pathological node: #{point["uuid"]}]"
    end

    # NSDataType1::getReferenceUnixtime(ns)
    def self.getReferenceUnixtime(ns)
        DateTime.parse(NSDataType1::getObjectReferenceDateTime(ns)).to_time.to_f
    end

    # NSDataType1::getFramesInTimeOrder(point)
    def self.getFramesInTimeOrder(point)
        Arrows::getTargetsOfGivenSetsForSource(point, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType1::getLastFrameOrNull(point)
    def self.getLastFrameOrNull(point)
        NSDataType1::getFramesInTimeOrder(point)
            .last
    end

    # NSDataType1::issueDescriptionInteractivelyOrNothing(point)
    def self.issueDescriptionInteractivelyOrNothing(point)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        NSDataTypeXExtended::issueDescriptionForTarget(point, description)
    end

    # NSDataType1::issueNewType1InteractivelyOrNull()
    def self.issueNewType1InteractivelyOrNull()
        node = NSDataType1::issue()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        if description != "" then
            NSDataTypeXExtended::issueDescriptionForTarget(node, description)
        end
        if LucilleCore::askQuestionAnswerAsBoolean("Create node content frame ? : ") then
            ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
            if ns0 then
                Arrows::issueOrException(node, ns0)
            end
        end
        node
    end

    # NSDataType1::openLastFrame(point)
    def self.openLastFrame(point)
        frame = NSDataType1::getLastFrameOrNull(point)
        if frame.nil? then
            puts "I could not find any frames for this point. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::openFrame(point, frame)
    end

    # NSDataType1::editLastFrame(point)
    def self.editLastFrame(point)
        frame = NSDataType1::getLastFrameOrNull(point)
        if frame.nil? then
            puts "I could not find any frames for this point. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::editFrame(point, frame)
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
        folderpath = DeskOperator::deskFolderpathForNSDataType1(point)
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
    end

    # NSDataType1::landing(object)
    def self.landing(object)

        loop {

            return if NyxObjects::getOrNull(object["uuid"]).nil?
            system("clear")

            NSDataType1::decacheObjectMetadata(object)

            menuitems = LCoreMenuItemsNX1.new()

            # Decache the object

            Miscellaneous::horizontalRule()

            if Miscellaneous::isAlexandra() then
                Asteroids::getAsteroidsForType1(object).each{|asteroid|
                    menuitems.item(
                        "parent: #{Asteroids::asteroidToString(asteroid)}",
                        lambda { Asteroids::landing(asteroid) }
                    )
                }
            end

            upstream = NSDataType1::getUpstreamType1s(object)
            upstream = NSDataType1::applyDateTimeOrderToType1s(upstream)
            upstream.each{|o|
                menuitems.item(
                    "parent: #{NSDataType1::toString(o)}",
                    lambda { NSDataType1::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            puts "[node]"

            description = NSDataType1::getObjectDescriptionOrNull(object)
            if description then
                puts "    description: #{description}"
            end
            puts "    uuid: #{object["uuid"]}"
            puts "    date: #{NSDataType1::getObjectReferenceDateTime(object)}"

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(object)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
            end

            Miscellaneous::horizontalRule()

            ns0 = NSDataType1::getLastFrameOrNull(object)
            if ns0 then
                NSDataType0s::decacheObjectMetadata(ns0)
                ordinal = menuitems.ordinal(lambda { NSDataType1::openLastFrame(object) })
                puts "[ #{ordinal}] #{NSDataType0s::frameToString(ns0)}"

                ordinal = menuitems.ordinal(lambda {
                    ns0 = NSDataType1::getLastFrameOrNull(object)
                    NSDataType0s::editFrame(object, ns0)
                })
                puts "[ #{ordinal}] edit data point"

                ordinal = menuitems.ordinal(lambda {
                    ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
                    return if ns0.nil?
                    Arrows::issueOrException(object, ns0)
                })
                puts "[ #{ordinal}] issue new data point"
            end

            downstream = NSDataType1::getDownstreamType1s(object)
            downstream = NSDataType1::applyDateTimeOrderToType1s(downstream)
            downstream.each{|o|
                menuitems.item(
                    NSDataType1::toString(o),
                    lambda { NSDataType1::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            description = NSDataType1::getObjectDescriptionOrNull(object)
            if description then
                menuitems.item(
                    "edit description",
                    lambda{
                        description = Miscellaneous::editTextSynchronously(description).strip
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(object, description)
                    }
                )
            else
                menuitems.item(
                    "set description",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(object, description)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "edit reference datetime",
                    lambda{
                        datetime = Miscellaneous::editTextSynchronously(NSDataType1::getObjectReferenceDateTime(object)).strip
                        return if !Miscellaneous::isDateTime_UTC_ISO8601(datetime)
                        NSDataTypeXExtended::issueDateTimeIso8601ForTarget(object, datetime)
                    }
                )
            end


            menuitems.item(
                "edit note",
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(object) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(object, text)
                }
            )


            menuitems.item(
                "attach parent node",
                lambda {
                    node = NSDT1Extended::selectExistingOrMakeNewType1()
                    return if node.nil?
                    Arrows::issueOrException(node, object)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "detach parent node",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", NSDataType1::getUpstreamType1s(object), lambda{|o| NSDataType1::toString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, object)
                    }
                )
            end

            menuitems.item(
                "attach child node (chosen from existing nodes)",
                lambda {
                    o = NSDT1Extended::selectExistingType1InteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(object, o)
                }
            )

            menuitems.item(
                "attach child node (new)",
                lambda {
                    o = NSDataType1::issueNewType1InteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(object, o)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "detach child node",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", NSDataType1::getDownstreamType1s(object), lambda{|o| NSDataType1::toString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, object)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove [this] as intermediary object", 
                    lambda { 
                        puts "intermediary node removal simulation"
                        NSDataType1::getUpstreamType1s(object).each{|upstreamnode|
                            puts "upstreamnode   : #{NSDataType1::toString(upstreamnode)}"
                        }
                        NSDataType1::getDownstreamType1s(object).each{|downstreampoint|
                            puts "downstreampoint: #{NSDataType1::toString(downstreampoint)}"
                        }
                        return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary object ? ")
                        NSDataType1::getUpstreamType1s(object).each{|upstreamnode|
                            NSDataType1::getDownstreamType1s(object).each{|downstreampoint|
                                Arrows::issueOrException(upstreamnode, downstreampoint)
                            }
                        }
                        NyxObjects::destroy(object)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "select nodes ; move to a new child node",
                    lambda {
                        return if NSDataType1::getDownstreamType1s(object).size == 0

                        # Selecting the points
                        points, _ = LucilleCore::selectZeroOrMore("object", [], NSDataType1::getDownstreamType1s(object), lambda{ |o| NSDataType1::toString(o) })
                        return if points.size == 0

                        # Creating the object
                        newobject = NSDataType1::issueNewType1InteractivelyOrNull()

                        # Setting the object as target of this one
                        Arrows::issueOrException(object, newobject)

                        # Moving the points
                        points.each{|o|
                            Arrows::issueOrException(newobject, o)
                        }
                        points.each{|o|
                            Arrows::remove(object, o)
                        }
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "destroy [this]",
                    lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this object ? ") then
                            NSDataType1::destroyProcedure(object)
                        end
                    }
                )
            end

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status

        }
    end

    # NSDataType1::getUpstreamType1s(object)
    def self.getUpstreamType1s(object)
        Arrows::getSourcesOfGivenSetsForTarget(object, [ "c18e8093-63d6-4072-8827-14f238975d04" ])
    end

    # NSDataType1::getDownstreamType1s(object)
    def self.getDownstreamType1s(object)
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
