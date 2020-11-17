
# encoding: UTF-8

class NavigationNodes

    # NavigationNodes::nodes()
    def self.nodes()
        NyxObjects2::getSet("f1ae7449-16d5-41c0-a89e-f2a8e486cc99")
    end

    # NavigationNodes::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "f1ae7449-16d5-41c0-a89e-f2a8e486cc99",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # NavigationNodes::issue(name1)
    def self.issue(name1)
        listing = NavigationNodes::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # NavigationNodes::issueNodeInteractivelyOrNull()
    def self.issueNodeInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("navigation node name: ")
        return nil if name1 == ""
        NavigationNodes::issue(name1)
    end

    # NavigationNodes::selectOneExistingNodeOrNull()
    def self.selectOneExistingNodeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("navigation node", NavigationNodes::nodes(), lambda{|l| NavigationNodes::toString(l) })
    end

    # NavigationNodes::selectOneExistingNodeOrMakeNewNodeOrNull()
    def self.selectOneExistingNodeOrMakeNewNodeOrNull()
        listing = NavigationNodes::selectOneExistingNodeOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no navigation node selected, create a new one ? ")
        NavigationNodes::issueNodeInteractivelyOrNull()
    end

    # NavigationNodes::selectNodeByNameCaseInsensitiveOrNull(name1)
    def self.selectNodeByNameCaseInsensitiveOrNull(name1)
        NavigationNodes::nodes().select{|node| node["name"].downcase == name1.downcase }.first
    end

    # NavigationNodes::searchAndReturnNavigationNodeOrNullIntellisense()
    def self.searchAndReturnNavigationNodeOrNullIntellisense()
        # lambda1: pattern: String -> Array[String]
        # lambda2: string:  String -> Object or null

        #{
        #    "objecttype"
        #    "objectuuid"
        #    "fragment"
        #    "object"
        #    "referenceunixtime"
        #}

        lambda1 = lambda { |pattern|
            Patricia::patternToOrderedSearchResults(pattern)
                .select{|item| GenericNyxObject::isNavigationNode(item["object"]) }
                .map{|item| item["fragment"] }
        }

        lambda2 = lambda { |fragment|
            Patricia::patternToOrderedSearchResults(fragment)
                .select{|item| item["fragment"] == fragment }
                .map{|item| item["object"] }
                .first
        }

        Miscellaneous::ncurseSelection1410(lambda1, lambda2)
    end

    # NavigationNodes::extractionSelectNavigationNodeOrMakeOneOrNull()
    def self.extractionSelectNavigationNodeOrMakeOneOrNull()
        loop {
            puts ""
            operations = ["select navigation node", "make navigation node", "return null"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return nil if operation.nil?
            if operation == "select navigation node" then
                listing = NavigationNodes::searchAndReturnNavigationNodeOrNullIntellisense()
                if listing then
                    puts "selected: #{GenericNyxObject::toString(listing)}"
                    operations = ["return navigation node", "landing only", "landing then return navigation node", "select navigation node descendant"]
                    operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                    next if operation.nil?
                    if operation == "return navigation node" then
                        return listing
                    end
                    if operation == "landing only" then
                        GenericNyxObject::landing(listing)
                    end
                    if operation == "landing then return navigation node" then
                        GenericNyxObject::landing(listing)
                        listing = NyxObjects2::getOrNull(listing["uuid"])
                        next if listing.nil?
                        return listing
                    end
                    if operation == "select navigation node descendant" then
                        d = GenericNyxObject::selectSelfOrDescendantOrNull(listing)
                        return d if d
                    end
                end
            end
            if operation == "make navigation node" then
                listing = NavigationNodes::issueNodeInteractivelyOrNull()
                if listing then
                    puts "made: #{GenericNyxObject::toString(listing)}"
                    if LucilleCore::askQuestionAnswerAsBoolean("Landing before returning ? ") then
                        GenericNyxObject::landing(listing)
                        listing = NyxObjects2::getOrNull(listing["uuid"])
                    end
                    next if listing.nil?
                    return listing
                end
            end
            if operation == "return null" then
                return nil
            end
        }
    end

    # NavigationNodes::toString(listing)
    def self.toString(listing)
        "[navigation node] #{listing["name"]}"
    end

    # NavigationNodes::arrayToconsecutivePairs(array)
    def self.arrayToconsecutivePairs(array)
        array1 = array.clone
        array2 = array.clone
        array1.reverse.drop(1).reverse.zip(array2.drop(1))
    end

    # NavigationNodes::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts NavigationNodes::toString(listing).green
            puts "uuid: #{listing["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            GenericNyxObject::getAllParentingPathsOfSize2(listing).each{|item|
                announce = "#{GenericNyxObject::toString(item["object"])} <- #{item["p2"] ? GenericNyxObject::toString(item["p2"]) : ""} -> #{GenericNyxObject::toString(item["p1"])}"
                mx.item(
                    "source: #{announce}",
                    lambda { GenericNyxObject::landing(item["p1"]) }
                )
            }

            targets = Arrows::getTargetsForSource(listing)
            targets = GenericNyxObject::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
            targets
                .each{|object|
                    mx.item(
                        "target: #{GenericNyxObject::toString(object)}",
                        lambda { GenericNyxObject::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(listing["name"]).strip
                return if name1 == ""
                listing["name"] = name1
                NyxObjects2::put(listing)
                NavigationNodes::removeSetDuplicates()
            })
            mx.item("make datapoint ; add as target".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(listing, datapoint)
            })
            mx.item("ensure navigation path".yellow, lambda {
                nameToNodeProcessSelfCreateIfNeeded = lambda {|name1, defaultNode|
                    if name1 == "[self]" then
                        return defaultNode
                    end
                    node = NavigationNodes::selectNodeByNameCaseInsensitiveOrNull(name1)
                    return node if node
                    NavigationNodes::issue(name1)
                }

                path = LucilleCore::askQuestionAnswerAsString("path: ")
                return if path == ""
                nodes = path
                            .split("->")
                            .map{|e| e.strip }
                            .map{|name1| nameToNodeProcessSelfCreateIfNeeded.call(name1, listing) }
                NavigationNodes::arrayToconsecutivePairs(nodes).each{|pair|
                    puts "linking: #{pair[0]["name"]} -> #{pair[1]["name"]}"
                    Arrows::issueOrException(pair[0], pair[1])
                }
            })
            mx.item("select object ; add as target".yellow, lambda { 
                o = Patricia::searchAndReturnObjectOrNullSequential()
                return if o.nil?
                Arrows::issueOrException(listing, o)
            })
            mx.item("select multiple targets ; inject navigation node".yellow, lambda {
                targets = Arrows::getTargetsForSource(listing)
                selectedtargets, _ = LucilleCore::selectZeroOrMore("target", [], targets, lambda{ |item| GenericNyxObject::toString(item) })
                name1 = LucilleCore::askQuestionAnswerAsString("new navigation node name (empty to abort): ")
                return if name1 == ""
                n1 = NavigationNodes::issue(name1)
                Arrows::issueOrException(listing, n1)
                selectedtargets.each{|target|
                    Arrows::issueOrException(n1, target)
                    Arrows::unlink(listing, target)
                }
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(listing)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy navigation node".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy navigation node: '#{NavigationNodes::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NavigationNodes::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("navigation nodes dive",lambda { 
                loop {
                    listings = NavigationNodes::nodes()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", listings, lambda{|l| NavigationNodes::toString(l) })
                    return if listing.nil?
                    NavigationNodes::landing(listing)
                }
            })

            ms.item("make new navigation node",lambda { 
                listing = NavigationNodes::issueNodeInteractivelyOrNull()
                return if listing.nil?
                NavigationNodes::landing(listing)
            })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
