
# encoding: UTF-8

class Patricia

    # --------------------------------------------------
    # Search

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

    # Patricia::searchAndLanding()
    def self.searchAndLanding()
        loop {
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("[synchronous] search pattern: ")
            return if pattern.size == 0
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
                system("clear")
                puts "search results for '#{pattern}':"
                ms = LCoreMenuItemsNX1.new()
                searchresults
                    .each{|sr| 
                        object = sr["object"]
                        next if NyxObjects2::getOrNull(object["uuid"]).nil? # could have been deleted in the previous loop
                        ms.item(
                            GenericNyxObject::toString(object), 
                            lambda { GenericNyxObject::landing(object) }
                        )
                    }
                status = ms.promptAndRunSandbox()
                break if !status
            }
        }
    end

    # Patricia::searchAndReturnObjectOrNullSequential()
    def self.searchAndReturnObjectOrNullSequential()
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
end