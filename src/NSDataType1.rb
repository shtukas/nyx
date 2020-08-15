
# encoding: UTF-8

class NSDataType1

    # NSDataType1::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataType1::objects()
    def self.objects()
        NyxObjects2::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects2::getOrNull(uuid)
    end

    # NSDataType1::toString(node)
    def self.toString(node)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{node["uuid"]}"
        str = KeyValueStore::getOrNull(nil, cacheKey)
        return str if str
        objects = Arrows::getTargetsForSource(node)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(node)
        if description then
            str = "[node] [#{node["uuid"][0, 4]}] #{description}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if description.nil? and objects.size > 0 then
            str = "[node] [#{node["uuid"][0, 4]}] #{GenericObjectInterface::toString(objects.first)}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if description.nil? and objects.size == 0 then
            str = "[node] [#{node["uuid"][0, 4]}] {no description, no dataline}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        raise "[error: 2b22ddb3-62c4-4940-987a-7a50330dcd36]"
    end

    # NSDataType1::getReferenceUnixtime(ns)
    def self.getReferenceUnixtime(ns)
        DateTime.parse(GenericObjectInterface::getObjectReferenceDateTime(ns)).to_time.to_f
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
        puts "node: #{JSON.pretty_generate(node)}"
        NSDataTypeXExtended::issueDescriptionForTarget(node, description)
        if LucilleCore::askQuestionAnswerAsBoolean("Create node data ? : ") then
            ns1 = NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
            if ns1 then
                Arrows::issueOrException(node, ns1)
            end
        end
        node
    end

    # NSDataType1::type1MatchesPattern(point, pattern)
    def self.type1MatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::toString(point).downcase.include?(pattern.downcase)
        return true if Arrows::getTargetsForSource(point).any?{|child| GenericObjectInterface::toString(child).downcase.include?(pattern.downcase) }
        false
    end

    # NSDataType1::selectType1sPerPattern(pattern)
    def self.selectType1sPerPattern(pattern)
        NSDataType1::objects()
            .select{|point| NSDataType1::type1MatchesPattern(point, pattern) }
    end

    # NSDataType1::destroy(point)
    def self.destroy(point)
        folderpath = DeskOperator::deskFolderpathForNSDataline(point)
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
        NyxObjects2::destroy(point)
    end

    # ---------------------------------------------

    # NSDataType1::getObjectDescriptionOrNull(object)
    def self.getObjectDescriptionOrNull(object)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(object)
    end

    # NSDataType1::decacheObjectMetadata(node)
    def self.decacheObjectMetadata(node)
        KeyValueStore::destroy(nil, "645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{node["uuid"]}") # flush the cached toString
    end

    # NSDataType1::landing(node)
    def self.landing(node)

        loop {

            return if NyxObjects2::getOrNull(node["uuid"]).nil?
            system("clear")

            NSDataType1::decacheObjectMetadata(node)

            menuitems = LCoreMenuItemsNX1.new()

            # Decache the node

            Miscellaneous::horizontalRule()

            upstreams = Arrows::getSourcesForTarget(node)
            upstreams = GenericObjectInterface::applyDateTimeOrderToObjects(upstreams)
            upstreams.each{|o|
                GenericObjectInterface::decacheObjectMetadata(o)
                menuitems.item(
                    "parent: #{GenericObjectInterface::toString(o)}",
                    lambda { GenericObjectInterface::envelop(o) }
                )
            }

            Miscellaneous::horizontalRule()

            puts "[node]"

            description = NSDataType1::getObjectDescriptionOrNull(node)
            if description then
                puts "    description: #{description}"
            end
            puts "    uuid: #{node["uuid"]}"
            puts "    date: #{GenericObjectInterface::getObjectReferenceDateTime(node)}"

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(node)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
            end

            Miscellaneous::horizontalRule()

            Arrows::getTargetsForSource(node).each{|object|
                GenericObjectInterface::decacheObjectMetadata(object)
                menuitems.item(
                    GenericObjectInterface::toString(object),
                    lambda{ GenericObjectInterface::envelop(object) }
                )
            }

            puts ""

            ordinal = menuitems.ordinal(lambda {
                dataline = NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
                return if dataline.nil?
                Arrows::issueOrException(node, dataline)
            })
            puts "[ #{ordinal}] issue new dataline"

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

            menuitems.item(
                "edit reference datetime",
                lambda{
                    datetime = Miscellaneous::editTextSynchronously(GenericObjectInterface::getObjectReferenceDateTime(node)).strip
                    return if !Miscellaneous::isDateTime_UTC_ISO8601(datetime)
                    NSDataTypeXExtended::issueDateTimeIso8601ForTarget(node, datetime)
                }
            )

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
                    n = NSDT1ExtendedUserInterface::selectExistingOrMakeNewType1()
                    return if n.nil?
                    Arrows::issueOrException(n, node)
                }
            )

            menuitems.item(
                "detach parent",
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", Arrows::getSourcesForTarget(node), lambda{|o| GenericObjectInterface::toString(o) })
                    return if ns.nil?
                    Arrows::remove(ns, node)
                }
            )

            menuitems.item(
                "attach child node (chosen from existing nodes)",
                lambda {
                    o = NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
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

            menuitems.item(
                "detach child",
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", Arrows::getTargetsForSource(node), lambda{|o| GenericObjectInterface::toString(o) })
                    return if ns.nil?
                    Arrows::remove(ns, node)
                }
            )

            menuitems.item(
                "remove [this] as intermediary node", 
                lambda { 
                    puts "intermediary node removal simulation"
                    Arrows::getSourcesForTarget(node).each{|upstreamnode|
                        puts "upstreamnode   : #{GenericObjectInterface::toString(upstreamnode)}"
                    }
                    Arrows::getTargetsForSource(node).each{|downstreamobject|
                        puts "downstream object: #{GenericObjectInterface::toString(downstreamobject)}"
                    }
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary node ? ")
                    Arrows::getSourcesForTarget(node).each{|upstreamnode|
                        Arrows::getTargetsForSource(node).each{|downstreamobject|
                            Arrows::issueOrException(upstreamnode, downstreamobject)
                        }
                    }
                    NyxObjects2::destroy(node)
                }
            )

            menuitems.item(
                "select nodes ; move to a new child node",
                lambda {
                    return if Arrows::getTargetsForSource(node).size == 0

                    # Selecting the nodes
                    selectednodes, _ = LucilleCore::selectZeroOrMore("object", [], Arrows::getTargetsForSource(node), lambda{ |o| GenericObjectInterface::toString(o) })
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

            menuitems.item(
                "select nodes ; move to an existing child node",
                lambda {
                    return if Arrows::getTargetsForSource(node).size == 0

                    # Selecting the nodes to moves
                    selectednodes, _ = LucilleCore::selectZeroOrMore("object", [], Arrows::getTargetsForSource(node), lambda{ |o| GenericObjectInterface::toString(o) })
                    return if selectednodes.size == 0

                    # Selecting or creating the node
                    targetnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", Arrows::getTargetsForSource(node), lambda{|o| GenericObjectInterface::toString(o) })
                    return if targetnode.nil?

                    # TODO: return if the selected new target is one of the nodes

                    # Moving the selectednodes
                    selectednodes.each{|o|
                        Arrows::issueOrException(targetnode, o)
                    }
                    selectednodes.each{|o|
                        Arrows::remove(node, o)
                    }
                }
            )

            menuitems.item(
                "destroy [this]",
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this node ? ") then
                        NSDataType1::destroy(node)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status
        }
    end
end
