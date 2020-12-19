
# encoding: UTF-8

class Patricia

    # -----------------------------------------------
    # is

    # Patricia::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # Patricia::isNGX15(object)
    def self.isNGX15(object)
        object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69"
    end

    # Patricia::isNavigationNode(object)
    def self.isNavigationNode(object)
        object["nyxNxSet"] == "f1ae7449-16d5-41c0-a89e-f2a8e486cc99"
    end

    # Patricia::isAsteroid(object)
    def self.isAsteroid(object)
        object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398"
    end

    # Patricia::isWave(object)
    def self.isWave(object)
        object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4"
    end

    # -----------------------------------------------
    # gets

    # Patricia::toString(object)
    def self.toString(object)
        if Patricia::isAsteroid(object) then
            return Asteroids::toString(object)
        end
        if Patricia::isNGX15(object) then
            return NGX15::toString(object)
        end
        if Patricia::isQuark(object) then
            return Quarks::toString(object)
        end
        if Patricia::isNavigationNode(object) then
            return NavigationNodes::toString(object)
        end
        if Patricia::isWave(object) then
            return Waves::toString(object)
        end
        puts object
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # Patricia::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        return object["referenceDateTime"] if object["referenceDateTime"]
        object["referenceDateTime"] = Time.at(object["unixtime"]).utc.iso8601
        NyxObjects2::put(object)
        object["referenceDateTime"]
    end

    # -----------------------------------------------
    # operations

    # Patricia::updateSearchLookupDatabase(object)
    def self.updateSearchLookupDatabase(object)
        if Patricia::isAsteroid(object) then
            SelectionLookupDataset::updateLookupForAsteroid(object)
        end
        if Patricia::isNGX15(object) then
            SelectionLookupDataset::updateLookupForNGX15(object)
        end
        if Patricia::isQuark(object) then
            SelectionLookupDataset::updateLookupForQuark(object)
        end
        if Patricia::isNavigationNode(object) then
            SelectionLookupDataset::updateLookupForNavigationNode(object)
        end
        if Patricia::isWave(object) then
            SelectionLookupDataset::updateLookupForWave(object)
        end
    end

    # Patricia::landing(object)
    def self.landing(object)
        if Patricia::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end

        if Patricia::isNGX15(object) then
            NGX15::landing(object)
            return
        end
        if Patricia::isQuark(object) then
            Quarks::landing(object)
            return
        end
        if Patricia::isNavigationNode(object) then
            NavigationNodes::landing(object)
            return
        end
        if Patricia::isWave(object) then
            Waves::waveDive(object)
            return 
        end
        puts object
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # Patricia::open1(object)
    def self.open1(object)
        if Patricia::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if Patricia::isNGX15(object) then
            NGX15::openNGX15(object)
            return
        end
        if Patricia::isQuark(object) then
            Quarks::open1(object)
            return
        end
        if Patricia::isNavigationNode(object) then
            NavigationNodes::landing(object)
            return
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # Patricia::destroy(object)
    def self.destroy(object)
        if Patricia::isAsteroid(object) then
            return
        end
        if Patricia::isNGX15(object) then
            NGX15::ngx15TerminationProtocolReturnBoolean(object)
            return
        end
        if Patricia::isQuark(object) then
            NyxObjects2::destroy(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end

    # --------------------------------------------------
    # User Interface (Part 1)

    # Patricia::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
    def self.selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
        targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(object)
        if targets.size == 0 then
            return nil
        end
        if targets.size == 1 then
            if LucilleCore::askQuestionAnswerAsBoolean("selecting target: '#{Patricia::toString(targets[0])}' confirm ? ", true) then
                return targets[0]
            end
            return nil
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda{|target| Patricia::toString(target) })
    end

    # Patricia::selectOneTargetOfThisObjectOrNull(asteroid)
    def self.selectOneTargetOfThisObjectOrNull(asteroid)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", TargetOrdinals::getTargetsForSourceInOrdinalOrder(asteroid), lambda{|t| Patricia::toString(t) })
    end

    # Patricia::selectZeroOrMoreTargetsFromThisObject(asteroid)
    def self.selectZeroOrMoreTargetsFromThisObject(asteroid)
        selected, _ = LucilleCore::selectZeroOrMore("target", [], TargetOrdinals::getTargetsForSourceInOrdinalOrder(asteroid), lambda{|t| Patricia::toString(t) })
        selected
    end

    # Patricia::selectOneParentOfThisObjectOrNull(asteroid)
    def self.selectOneParentOfThisObjectOrNull(asteroid)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", Arrows::getSourcesForTarget(asteroid), lambda{|t| Patricia::toString(t) })
    end

    # --------------------------------------------------
    # User Interface (Part 2)

    # Patricia::mxSourcing(object, mx)
    def self.mxSourcing(object, mx)
        Patricia::getAllParentingPathsOfSize2(object).each{|item|
            sourcing = "#{Patricia::toString(item["p1"])}#{item["p2"] ? " <- #{Patricia::toString(item["p2"])}" : ""}"
            mx.item(
                "source: #{sourcing}",
                lambda { Patricia::landing(item["p1"]) }
            )
        }
    end

    # Patricia::mxTargetting(object, mx)
    def self.mxTargetting(object, mx)
        targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(object)
        targets
            .each{|target|
                mx.item("target ( #{"%6.3f" % TargetOrdinals::getTargetOrdinal(object, target)} ) #{Patricia::toString(target)}", lambda { 
                    Patricia::landing(target) 
                })
            }
    end

    # Patricia::mxParentsManagement(object, mx)
    def self.mxParentsManagement(object, mx)
        mx.item("add parent".yellow, lambda {
            o1 = Patricia::architect()
            return if o1.nil?
            Arrows::issueOrException(o1, object)
        })

        mx.item("remove parent".yellow, lambda {
            parents = Arrows::getSourcesForTarget(object)
            parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", parents, lambda { |parent| Patricia::toString(parent) })
            return if parent.nil?
            Arrows::unlink(parent, object)
        })
    end

    # Patricia::mxTargetsManagement(object, mx)
    def self.mxTargetsManagement(object, mx)

        mx.item("add new target at ordinal".yellow, lambda { 
            o1 = Patricia::architect()
            return if o1.nil?
            Arrows::issueOrException(object, o1)
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            if ordinal == 0 then
                ordinal = ([1] + TargetOrdinals::getTargetsForSourceInOrdinalOrder(object).map{|target| TargetOrdinals::getTargetOrdinal(object, target) }).max
            end
            TargetOrdinals::setTargetOrdinal(object, o1, ordinal)
        })

        mx.item("update target's ordinal".yellow, lambda { 
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", TargetOrdinals::getTargetsForSourceInOrdinalOrder(object), lambda{|t| Patricia::toString(t) })
            return if target.nil?
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            TargetOrdinals::setTargetOrdinal(object, target, ordinal)
        })

        mx.item("remove target".yellow, lambda { 
            targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(object)
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda { |target| Patricia::toString(target) })
            return if target.nil?
            Arrows::unlink(object, target)
        })
    end

    # Patricia::mxMoveToNewParent(object, mx)
    def self.mxMoveToNewParent(object, mx)
        mx.item("move to new parent".yellow, lambda {
            sources = Arrows::getSourcesForTarget(object)
            newparent = Patricia::architect()
            return if newparent.nil?
            Arrows::issueOrException(newparent, object)
            sources.each{|source|
                Arrows::unlink(source, object)
            }
        })
    end

    # --------------------------------------------------
    # Genealogy

    # Patricia::selectSelfOrDescendantOrNull(object)
    def self.selectSelfOrDescendantOrNull(object)
        loop {
            puts ""
            puts "object: #{Patricia::toString(object)}"
            puts "targets:"
            Arrows::getTargetsForSource(object).each{|target|
                puts "    #{Patricia::toString(target)}"
            }
            operations = ["return object", "select and return one target", "select and focus on target", "return null"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return nil if operation.nil?
            if operation == "return object" then
                return object
            end
            if operation == "select and return one target" then
                t = Patricia::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
                if t then
                    return t
                end
            end
            if operation == "select and focus on target" then
                t =  Patricia::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
                if t then
                    return Patricia::selectSelfOrDescendantOrNull(t)
                end
            end
            if operation == "return null" then
                return nil
            end
        }
    end

    # Patricia::getAllParentingPathsOfSize2(object)
    def self.getAllParentingPathsOfSize2(object)
        Arrows::getSourcesForTarget(object).map{|source|
            {
                "object" => object,
                "p1"     => source
            }
        }.map{|item|
            sources = Arrows::getSourcesForTarget(item["p1"])
            if sources.size > 0 then
                sources.map{|source|
                    item["p2"] = source
                    item
                }
            else
                item["p2"] = nil
                item
            end

        }
        .flatten
    end

    # --------------------------------------------------
    # Search Utils

    # Patricia::patternToOrderedSearchResults(pattern)
    def self.patternToOrderedSearchResults(pattern)
        records = SelectionLookupDataset::patternToRecords(pattern)
        #{
        #    "objecttype"
        #    "objectuuid"
        #    "fragment"
        #}
        searchresults = records
                            .map{|record|
                                record["object"] = NyxObjects2::getOrNull(record["objectuuid"])
                                record
                            }
                            .select{|record|
                                !record["object"].nil?
                            }
        #{
        #    "objecttype"
        #    "objectuuid"
        #    "fragment"
        #    "object"
        #}
        searchresults
            .sort{|i1, i2| i1["object"]["unixtime"] <=> i2["object"]["unixtime"] }
    end

    # --------------------------------------------------
    # Search Interface

    # Patricia::sequentialSearchAndReturnObjectOrNull()
    def self.sequentialSearchAndReturnObjectOrNull()
        answer = nil
        loop {
            break if answer
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("[synchronous] search pattern: ")
            return nil if pattern.size == 0
            next if pattern.size < 3
            searchresults = Patricia::patternToOrderedSearchResults(pattern)
            #{
            #    "objecttype"
            #    "objectuuid"
            #    "fragment"
            #    "object"
            #    "referenceunixtime"
            #}
            loop {
                break if answer
                system("clear")
                puts "search results for '#{pattern}':"
                ms = LCoreMenuItemsNX1.new()
                searchresults
                    .each{|sr| 
                        ms.item(
                            Patricia::toString(sr["object"]), 
                            lambda { answer = sr["object"] }
                        )
                    }
                status = ms.promptAndRunSandbox()
                break if !status
            }
        }
        answer
    end

    # Patricia::interactiveSearchAndReturnObjectOrNull()
    def self.interactiveSearchAndReturnObjectOrNull()
        fragments = SelectionLookupDatabaseIO::getDatabaseRecords().map{|record| "#{record["fragment"]} -" }
        fragment = Pepin.search(fragments)
        fragment = fragment[0, fragment.size-2]
        searchresults = Patricia::patternToOrderedSearchResults(fragment)
        if searchresults.size == 1 then
            object = searchresults[0]["object"]
            if LucilleCore::askQuestionAnswerAsBoolean("return '#{Patricia::toString(object)}' ? ", true) then
                return object
            end
            return nil
        end
        answer = nil
        ms = LCoreMenuItemsNX1.new()
        searchresults
            .sort{|sr1, sr2| sr1["object"]["unixtime"] <=> sr2["object"]["unixtime"] }
            .each{|sr| 
                ms.item(Patricia::toString(sr["object"]), lambda { 
                    answer = sr["object"] 
                })
            }
        status = ms.promptAndRunSandbox()
        answer
    end

    # Patricia::searchAndReturnObjectOrNull()
    def self.searchAndReturnObjectOrNull()
        atricia::interactiveSearchAndReturnObjectOrNull()
    end

    # Patricia::searchAndLanding()
    def self.searchAndLanding()
        object = Patricia::searchAndReturnObjectOrNull()
        return if object.nil?
        Patricia::landing(object)
    end

    # --------------------------------------------------
    # Maker

    # Patricia::makeNewObjectOrNull()
    def self.makeNewObjectOrNull()
        loop {
            options = ["line", "quark", "NGX15", "navigation node", "asteroid"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return nil if option.nil?
            if option == "line" then
                line = LucilleCore::askQuestionAnswerAsString("line: ")
                quark = Quarks::makeLine(line)
                quark["description"] = line
                NyxObjects2::put(quark)
                return quark
            end
            if option == "quark" then
                object = Quarks::issueNewQuarkInteractivelyOrNull()
                return object if object
            end
            if option == "NGX15" then
                object = NGX15::issueNewNGX15InteractivelyOrNull()
                return object if object
            end
            if option == "navigation node" then
                object = NavigationNodes::issueNodeInteractivelyOrNull()
                return object if object
            end
            if option == "asteroid" then
                object = Asteroids::issueAsteroidInteractivelyOrNull()
                return object if object
            end
        }
    end

    # --------------------------------------------------
    # Architect

    # Patricia::issueNewDatapointOrNull()
    def self.issueNewDatapointOrNull()
        # This function is a blend of Quarks::issueNewQuarkInteractivelyOrNull() and NGX15::issueNewNGX15InteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "url", "aion-point", "NGX15"])
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            quark = Quarks::makeLine(line)
            quark["description"] = line
            NyxObjects2::put(quark)
            return quark
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            quark = Quarks::makeUrl(url)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            NyxObjects2::put(quark)
            return quark
        end
        if type == "aion-point" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
            aionFileSystemLocation = "/Users/pascal/Desktop/#{locationname}"
            quark = Quarks::makeAionFileSystemLocation(aionFileSystemLocation)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            NyxObjects2::put(quark)
            return quark
        end
        if type == "NGX15" then
            return NGX15::issueNewNGX15InteractivelyOrNull()
        end
        nil
    end

    # Patricia::makeNewUnsavedDatapointForTransmutationInteractivelyOrNull()
    def self.makeNewUnsavedDatapointForTransmutationInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["quark", "NGX15"])
        if type == "quark" then
            return Quarks::makeUnsavedQuarkForTransmutationInteractivelyOrNull()
        end
        if type == "NGX15" then
            return NGX15::makeUnsavedNGX15ForTransmutationInteractivelyOrNull()
        end
        nil
    end

    # Patricia::architect()
    def self.architect()
        landingBehindAsk = lambda {|object|
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to land on '#{Patricia::toString(object)}' ? ", false) then
                Patricia::landing(object)
            end
        }
        loop {
            options = ["make new object", "search existing objects"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return nil if option.nil?
            if option == "make new object" then
                object = Patricia::makeNewObjectOrNull()
                if object then
                    landingBehindAsk.call(object)
                    return object
                end
            end
            if option == "search existing objects" then
                object = Patricia::searchAndReturnObjectOrNull()
                if object then
                    landingBehindAsk.call(object)
                    return object
                end
            end
        }
    end
end
