
# encoding: UTF-8

class NSDataPoint

    # NSDataPoint::datapoints()
    def self.datapoints()
        NyxObjects2::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # NSDataPoint::getDataPointParents(datapoint)
    def self.getDataPointParents(datapoint)
        Arrows::getSourcesForTarget(datapoint)
    end

    # NSDataPoint::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # NSDataPoint::issueNavigation(description)
    def self.issueNavigation(description)
        object = {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"    => Time.new.to_f,
            "type"        => "navigation",
            "description" => description
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueLine(line)
    def self.issueLine(line)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "line",
            "line"       => line
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueUrl(url)
    def self.issueUrl(url)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "url",
            "url"        => url
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueNyxHub(hubname)
    def self.issueNyxHub(hubname)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxHub",
            "name"       => hubname
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueNyxFile(nyxFileName)
    def self.issueNyxFile(nyxFileName)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxFile",
            "name"       => nyxFileName
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataPoint::issueNewPointInteractivelyOrNull()
    def self.issueNewPointInteractivelyOrNull()
        types = ["navigation", "line", "url", "text", "NyxFile", "NyxHub"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "navigation" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description.size == 0
            return NSDataPoint::issueNavigation(description)
        end
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return NSDataPoint::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return NSDataPoint::issueUrl(url)
        end
        if type == "text" then
            nyxfilename = "NyxFile-#{SecureRandom.uuid}.txt"
            filepath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/CatalystElements/#{Time.new.strftime("%Y-%m")}/#{nyxfilename}"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            FileUtils.touch(filepath)
            system("open '#{filepath}'")
            LucilleCore::pressEnterToContinue()
            return NSDataPoint::issueNyxFile(nyxfilename)
        end
        if type == "NyxFile" then
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["nyxfilename already exists", "issue new nyxfilename"])
            return nil if op.nil?
            if op == "nyxfilename already exists" then
                nyxfilename = LucilleCore::askQuestionAnswerAsString("nyxfile name: ")
                return nil if nyxfilename.size == 0
            end
            if op == "issue new nyxfilename" then
                extention = LucilleCore::askQuestionAnswerAsString("extension with dot: ")
                return nil if extention != ""
                nyxfilename = "NyxFile-#{SecureRandom.uuid}#{extention}"
                puts "nyxfilename: #{nyxfilename}"
                LucilleCore::pressEnterToContinue()
            end
            return NSDataPoint::issueNyxFile(nyxfilename)
        end
        if type == "NyxHub" then
            hubname = "NyxHub-#{SecureRandom.uuid}"
            puts "hubname: #{hubname}"
            LucilleCore::pressEnterToContinue()
            return NSDataPoint::issueNyxHub(hubname)
        end
    end

    # NSDataPoint::toStringUseTheForce(datapoint)
    def self.toStringUseTheForce(datapoint)
        if datapoint["description"] then
            return "[#{datapoint["type"]}] #{datapoint["description"]}"
        end
        if datapoint["type"] == "navigation" then
            return "[#{datapoint["type"]}] {no description}"
        end
        if datapoint["type"] == "line" then
            return "[#{datapoint["type"]}] #{datapoint["line"]}"
        end
        if datapoint["type"] == "url" then
            return "[#{datapoint["type"]}] #{datapoint["url"]}"
        end
        if datapoint["type"] == "NyxFile" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        if datapoint["type"] == "NyxHub" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        puts datapoint
        raise "[NSDataPoint error d39378dc]"
    end

    # NSDataPoint::toString(datapoint, useCachedValue = true)
    def self.toString(datapoint, useCachedValue = true)
        cacheKey = "e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{datapoint["uuid"]}"
        if useCachedValue then
            str = KeyValueStore::getOrNull(nil, cacheKey)
            return str if str
        end
        str = NSDataPoint::toStringUseTheForce(datapoint)
        KeyValueStore::set(nil, cacheKey, str)
        str
    end

    # NSDataPoint::accessopen(datapoint)
    def self.accessopen(datapoint)
        if datapoint["type"] == "line" then
            puts "line: #{datapoint["line"]}"
            if LucilleCore::askQuestionAnswerAsBoolean("edit line ? : ", false) then
                line = datapoint["line"]
                line = Miscellaneous::editTextSynchronously(line).strip
                return NSDataPoint::issueLine(line)
            end
            return nil
        end
        if datapoint["type"] == "url" then
            puts "url: #{datapoint["url"]}"
            system("open '#{datapoint["url"]}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit url ? : ", false) then
                url = datapoint["url"]
                url = Miscellaneous::editTextSynchronously(url).strip
                return NSDataPoint::issueUrl(url)
            end
            return nil
        end
        if datapoint["type"] == "NyxFile" then
            location = NSDatapointNyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "filepath: #{location}"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["name"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "NyxHub" then
            location = NSDatapointNyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "target file '#{location}'"
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["name"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        puts datapoint
        raise "[NSDataPoint error e12fc718]"
    end

    # NSDataPoint::landing(datapoint)
    def self.landing(datapoint)
        loop {

            return if NyxObjects2::getOrNull(datapoint["uuid"]).nil?

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            puts JSON.pretty_generate(datapoint).yellow
            puts "[datapoint]".yellow

            puts "    #{NSDataPoint::toString(datapoint, false)}"
            puts "    uuid: #{datapoint["uuid"]}".yellow
            puts "    date: #{GenericObjectInterface::getObjectReferenceDateTime(datapoint)}".yellow

            puts ""

            menuitems.item(
                "open".yellow,
                lambda { NSDataPoint::accessopen(datapoint) }
            )

            menuitems.item(
                "set/update description".yellow,
                lambda{
                    description = Miscellaneous::editTextSynchronously(datapoint["description"] || "").strip
                    return if description == ""
                    datapoint["description"] = description
                    NyxObjects2::put(datapoint)
                }
            )

            menuitems.item(
                "edit reference datetime".yellow,
                lambda{
                    datetime = Miscellaneous::editTextSynchronously(datapoint["referenceDateTime"] || Time.new.utc.iso8601).strip
                    datapoint["referenceDateTime"] = datetime
                    NyxObjects2::put(datapoint)
                }
            )

            menuitems.item(
                "[sandbox selection]".yellow,
                lambda{ KeyValueStore::set(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546", JSON.generate(datapoint)) }
            )

            menuitems.item(
                "remove [this] as intermediary node".yellow, 
                lambda { 
                    puts "intermediary node removal simulation"
                    Arrows::getSourcesForTarget(datapoint).each{|upstreamnode|
                        puts "upstreamnode   : #{GenericObjectInterface::toString(upstreamnode)}"
                    }
                    Arrows::getTargetsForSource(datapoint).each{|downstreamobject|
                        puts "downstream object: #{GenericObjectInterface::toString(downstreamobject)}"
                    }
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary node ? ")
                    Arrows::getSourcesForTarget(datapoint).each{|upstreamnode|
                        Arrows::getTargetsForSource(datapoint).each{|downstreamobject|
                            Arrows::issueOrException(upstreamnode, downstreamobject)
                        }
                    }
                    NyxObjects2::destroy(datapoint)
                }
            )

            menuitems.item(
                "destroy [this]".yellow,
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{NSDataPoint::toString(datapoint)}': ") then
                        NyxObjects2::destroy(datapoint)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            puts "[parents]".yellow
            puts ""

            Arrows::getSourcesForTarget(datapoint)
                .each{|o|
                    menuitems.item(
                        "parent: #{GenericObjectInterface::toString(o)}",
                        lambda { GenericObjectInterface::landing(o) }
                    )
                }

            puts ""

            menuitems.item(
                "attach parent node".yellow,
                lambda {
                    n = NSDataPointsExtended::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if n.nil?
                    Arrows::issueOrException(n, datapoint)
                }
            )

            menuitems.item(
                "detach parent".yellow,
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", Arrows::getSourcesForTarget(node), lambda{|o| GenericObjectInterface::toString(o) })
                    return if ns.nil?
                    Arrows::unlink(ns, datapoint)
                }
            )

            Miscellaneous::horizontalRule()

            puts "[children]".yellow

            targets = Arrows::getTargetsForSource(datapoint)
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|o|
                menuitems.item(
                    GenericObjectInterface::toString(o, false),
                    lambda{ GenericObjectInterface::landing(o) }
                )
            }

            puts ""

            menuitems.item(
                "issue node ; attach as child".yellow,
                lambda{
                    child = NSDataPoint::issueNewPointInteractivelyOrNull()
                    return if child.nil?
                    Arrows::issueOrException(datapoint, child)
                    if child["type"] != "navigation" then
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        if description != "" then
                            child["description"] =  description
                            NyxObjects2::put(child)
                        end
                    end
                }
            )

            menuitems.item(
                "select from existing nodes ; attach as child".yellow,
                lambda {
                    o = NSDataPointsExtended::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if o.nil?
                    Arrows::issueOrException(datapoint, o)
                }
            )

            menuitems.item(
                "detach child".yellow,
                lambda {
                    targets = Arrows::getTargetsForSource(datapoint)
                    targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| GenericObjectInterface::toString(o) })
                    return if ns.nil?
                    Arrows::unlink(datapoint, ns)
                }
            )

            menuitems.item(
                "select children ; move to existing/new node".yellow,
                lambda {
                    return if Arrows::getTargetsForSource(datapoint).size == 0

                    targets = Arrows::getTargetsForSource(datapoint)
                    targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)

                    # Selecting the nodes to moves
                    selectednodes, _ = LucilleCore::selectZeroOrMore("object", [], targets, lambda{ |o| GenericObjectInterface::toString(o) })
                    return if selectednodes.size == 0

                    # Selecting or creating the node
                    selectTargetNode = lambda { |node|
                        mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["existing child node", "new child node", "new independant node"])
                        return nil if mode.nil?
                        if mode == "existing child node" then
                            targets = Arrows::getTargetsForSource(node)
                            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
                            return LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| GenericObjectInterface::toString(o) })
                        end
                        if mode == "new child node" then
                            childnode = NSDataPoint::issueNewPointInteractivelyOrNull()
                            return nil if childnode.nil?
                            Arrows::issueOrException(node, childnode)
                            return childnode
                        end
                        if mode == "new independant node" then
                            xnode = NSDataPoint::issueNewPointInteractivelyOrNull()
                            return nil if xnode.nil?
                            return xnode
                        end
                    }

                    targetnode = selectTargetNode.call(datapoint)
                    return if targetnode.nil?

                    # TODO: return if the selected new target is one of the nodes

                    # Moving the selectednodes
                    selectednodes.each{|o|
                        Arrows::issueOrException(targetnode, o)
                    }
                    selectednodes.each{|o|
                        Arrows::unlink(datapoint, o)
                    }
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.promptAndRunSandbox()

            break if !status

            break if KeyValueStore::getOrNull(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546") # Looks like we were in sandbox mode and something was selected.
        }
    end

    # NSDataPoint::destroy(datapoint)
    def self.destroy(datapoint)

        puts "Destroying datapoint: #{NSDataPoint::toString(datapoint)}"

        if datapoint["type"] == "line" then

        end
        if datapoint["type"] == "url" then

        end
        if datapoint["type"] == "NyxFile" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy target NyxFile file ? ") then
                location = NSDatapointNyxElementLocation::getLocationByAllMeansOrNull(datapoint)
                if location then
                    FileUtils.rm(location)
                else
                    puts "Failure to find the target file."
                    if !LucilleCore::askQuestionAnswerAsBoolean("Is this expected ? ") then
                        puts "Very well. Exiting."
                        exit
                    end
                end
            end

        end
        if datapoint["type"] == "NyxHub" then
            puts "Datapoint is NyxHub, we are going to remove the NyxHub file..."
            location = NSDatapointNyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-NyxHubs" then
                    puts "Found NyxHub: #{location}"
                    parent = File.dirname(location)
                    puts "Going to remove the parent folder: #{parent}"
                    LucilleCore::removeFileSystemLocation(parent)
                else
                    # We are in the interesting case of an asteroid with a NyxHud child which is not in Asteroids-NyxHubs
                    puts "Actually I am going to let you do that..."
                    sleep 3
                    system("open '#{File.dirname(location)}'")
                    LucilleCore::pressEnterToContinue()
                end
            else
                puts "Failure to find the file."
                if !LucilleCore::askQuestionAnswerAsBoolean("Is this expected ? ") then
                    puts "Very well. Exiting."
                    exit
                end
            end
        end

        NyxObjects2::destroy(datapoint)
    end
end
