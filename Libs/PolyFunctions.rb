class PolyFunctions

    # ordering: alphabetical

    # PolyFunctions::bankAccountsForItem(item)
    def self.bankAccountsForItem(item)
        accounts = []

        accounts << {
            "description" => PolyFunctions::genericDescription(item),
            "number"      => item["uuid"]
        }

        if item["mikuType"] == "NxOTimeCommitment" then
            tcId = item["tcId"]
            wtc = NxWTimeCommitments::getOrNull(tcId)
            accounts << {
                "description" => PolyFunctions::genericDescription(wtc),
                "number"      => wtc["uuid"]
            }
        end

        if item["mikuType"] == "NxTodo" then
            tcId = item["tcId"]
            wtc = NxWTimeCommitments::getOrNull(tcId)
            accounts << {
                "description" => PolyFunctions::genericDescription(wtc),
                "number"      => wtc["uuid"]
            }
        end

        if item["mikuType"] == "Vx01" then
            tcId = item["tcId"]
            wtc = NxWTimeCommitments::getOrNull(tcId)
            if wtc then
                accounts << {
                    "description" => PolyFunctions::genericDescription(wtc),
                    "number"      => wtc["uuid"]
                }
            end
        end

        if item["mikuType"] == "Wave" then
            tcId = item["tcId"]
            wtc = NxWTimeCommitments::getOrNull(tcId)
            if wtc then
                accounts << {
                    "description" => PolyFunctions::genericDescription(wtc),
                    "number"      => wtc["uuid"]
                }
            end
        end

        accounts
    end

    # PolyFunctions::edit(item) # item
    def self.edit(item)

        puts "PolyFunctions::edit(#{JSON.pretty_generate(item)})"

        # order: by mikuType

        if item["mikuType"] == "NxTodo" then
            return NxTodos::edit(item)
        end

        if item["mikuType"] == "Wave" then
            return Waves::edit(item)
        end

        if item["mikuType"] == "NxTodo" then
            return NxTodos::edit(item)
        end

        puts "I do not know how to PolyFunctions::edit(#{JSON.pretty_generate(item)})"
        raise "(error: 628167a9-f6c9-4560-bdb0-4b0eb9579c86)"
    end

    # PolyFunctions::foxTerrierAtItem(item)
    def self.foxTerrierAtItem(item)
        loop {
            system("clear")
            puts "------------------------------".green
            puts "Fox Terrier Or Null (`select`)".green
            puts "------------------------------".green
            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)

            entities = []
            if entities.size > 0 then
                puts ""
                puts "parents:"
                entities
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
                    }
            end

            entities = []
            if entities.size > 0 then
                puts ""
                puts "related:"
                entities
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
                    }
            end

            entities = []
            if entities.size > 0 then
                puts ""
                puts "parents:"
                entities
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
                    }
            end

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return nil if input == ""

            if input == "select" then
                return item
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                return if entity.nil?
                resultOpt = PolyFunctions::foxTerrierAtItem(entity)
                return resultOpt if resultOpt
            end
        }
    end

    # PolyFunctions::genericDescription(item)
    def self.genericDescription(item)

        # ordering: alphabetical order

        if item["mikuType"] == "InboxItem" then
            return item["description"]
        end
        if item["mikuType"] == "NsTopLine" then
            return item["line"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
        if item["mikuType"] == "NxIced" then
            return item["description"]
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return item["description"]
        end
        if item["mikuType"] == "NxWTimeCommitment" then
            return item["description"]
        end
        if item["mikuType"] == "NxOndate" then
            return item["description"]
        end
        if item["mikuType"] == "NxTodo" then
            return item["description"]
        end
        if item["mikuType"] == "TxStratosphere" then
            return item["description"]
        end
        if item["mikuType"] == "TxManualCountDown" then
            return item["description"]
        end
        if item["mikuType"] == "TxThread" then
            return item["description"]
        end
        if item["mikuType"] == "Vx01" then
            return item["description"]
        end
        if item["mikuType"] == "Wave" then
            return item["description"]
        end

        raise "(error: bd77060a-84e0-4940-a20f-8bf3f4aced34) no generic description defined for item: #{JSON.pretty_generate(item)}"
    end

    # PolyFunctions::timeBeforeNotificationsInHours(item)
    def self.timeBeforeNotificationsInHours(item)
        1
    end

    # PolyFunctions::toString(item)
    def self.toString(item)

        # order: lexicographic

        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxNode" then
            return NxNodes::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxOTimeCommitment" then
            return NxOTimeCommitments::toString(item)
        end
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTimeCommitments::toString(item)
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item)
        end
        if item["mikuType"] == "NxTriage" then
            return NxTriages::toString(item)
        end
        if item["mikuType"] == "TxStratosphere" then
            return TxStratospheres::toString(item)
        end
        if item["mikuType"] == "TxManualCountDown" then
            return "(countdown) #{item["description"]}: #{item["counter"]}"
        end
        if item["mikuType"] == "Vx01" then
            return "(-vx-) #{item["description"]}"
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::toStringForCatalystListing(item)
    def self.toStringForCatalystListing(item)
        if item["mikuType"] == "NxWTimeCommitment" then
            return NxWTimeCommitments::toStringWithDetails(item, true)
        end
        PolyFunctions::toString(item)
    end

    # PolyFunctions::toStringForSearchListing(item)
    def self.toStringForSearchListing(item)
        if item["mikuType"] == "Wave" then
            return Waves::toStringForSearch(item)
        end
        PolyFunctions::toString(item)
    end
end
