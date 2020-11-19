
# encoding: UTF-8

class Patricia

    # --------------------------------------------------
    # Genealogy

    # Patricia::selectSelfOrDescendantOrNull(object)
    def self.selectSelfOrDescendantOrNull(object)
        loop {
            puts ""
            puts "object: #{GenericNyxObject::toString(object)}"
            puts "targets:"
            Arrows::getTargetsForSource(object).each{|target|
                puts "    #{GenericNyxObject::toString(target)}"
            }
            operations = ["return object", "select and return one target", "select and focus on target", "return null"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return nil if operation.nil?
            if operation == "return object" then
                return object
            end
            if operation == "select and return one target" then
                t = GenericNyxObject::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
                if t then
                    return t
                end
            end
            if operation == "select and focus on target" then
                t =  GenericNyxObject::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
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
                            .map{|record|
                                object = record["object"]
                                record["referenceunixtime"] = DateTime.parse(GenericNyxObject::getObjectReferenceDateTime(object)).to_time.to_f
                                record
                            }
        #{
        #    "objecttype"
        #    "objectuuid"
        #    "fragment"
        #    "object"
        #    "referenceunixtime"
        #}
        searchresults
            .sort{|i1, i2| i1["referenceunixtime"] <=> i2["referenceunixtime"] }
    end

    # --------------------------------------------------
    # Search Interface

    # Patricia::searchSequentialAndReturnObjectOrNull()
    def self.searchSequentialAndReturnObjectOrNull()
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
                            GenericNyxObject::toString(sr["object"]), 
                            lambda { answer = sr["object"] }
                        )
                    }
                status = ms.promptAndRunSandbox()
                break if !status
            }
        }
        answer
    end

    # Patricia::searchAndLanding()
    def self.searchAndLanding()
        object = Patricia::searchSequentialAndReturnObjectOrNull()
        return if object.nil?
        GenericNyxObject::landing(object)
    end

    # --------------------------------------------------
    # Maker

    # Patricia::makeNewObjectOrNull()
    def self.makeNewObjectOrNull()
        loop {
            options = ["asteroid"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return nil if option.nil?
            if option == "asteroid" then
                object = Asteroids::issueAsteroidInteractivelyOrNull()
                return object if object
            end
        }
    end

    # --------------------------------------------------
    # Architect

    # Patricia::searchAndReturnObjectOrMakeNewObjectOrNull()
    def self.searchAndReturnObjectOrMakeNewObjectOrNull()
        loop {
            options = ["search existing objects", "make new object"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return nil if option.nil?
            if option == "search existing objects" then
                object = Patricia::searchSequentialAndReturnObjectOrNull()
                return object if object
            end
            if option == "make new object" then
                object = Patricia::makeNewObjectOrNull()
                return object if object
            end
        }
    end
end