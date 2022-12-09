class PolyFunctions

    # ordering: alphabetical

    # PolyFunctions::bankAccountsForItem(item)
    def self.bankAccountsForItem(item)
        accounts = []

        accounts << {
            "description" => PolyFunctions::genericDescription(item),
            "number"      => item["uuid"]
        }

        if item["mikuType"] != "Cx22" then
            cx22 = Cx22Mapping::itemToCx22IncludingInteractiveAttempt(item)
            if cx22 then
                accounts << {
                "description" => cx22["description"],
                "number"      => cx22["uuid"]
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

            entities = Nx7::parents(item)
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

            entities = Nx7::relateds(item)
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

            entities = Nx7::children(item)
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

        if item["mikuType"] == "Cx22" then
            return item["description"]
        end
        if item["mikuType"] == "InboxItem" then
            return item["description"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
        if item["mikuType"] == "NxIced" then
            return item["description"]
        end
        if item["mikuType"] == "NxOndate" then
            return item["description"]
        end
        if item["mikuType"] == "NxTodo" then
            return item["description"]
        end
        if item["mikuType"] == "Nx7" then
            return item["description"]
        end
        if item["mikuType"] == "TxFloat" then
            return item["description"]
        end
        if item["mikuType"] == "TxProject" then
            return item["description"]
        end
        if item["mikuType"] == "TxThread" then
            return item["description"]
        end
        if item["mikuType"] == "Wave" then
            return item["description"]
        end

        raise "(error: bd77060a-84e0-4940-a20f-8bf3f4aced34) no generic description defined for item: #{JSON.pretty_generate(item)}"
    end

    # PolyFunctions::listingPriorityOrNull(item)
    # We return a null value when the item should not be displayed
    def self.listingPriorityOrNull(item) # Float between 0 and 1

        # This is the primary definition

        # NxAnniversary                             0.95
        # Wave "ns:mandatory-today"                 0.94
        # Cx22 isWork                               0.93
        # NxTriage                                  0.92
        # TxManualCountDown                         0.90
        # NxOndate                                  0.79
        # Cx22                                      0.78
        # NxTodo with Cx22                          0.78
        # TxProject                                 0.77
        # Wave "ns:time-important"                  0.70
        # ----------------------------------------- 0.50 (above should ideally be done before bed, below yellow)
        # Wave "ns:beach"                           0.40 
        # NxTodo                                    0.30 Without Cx22

        shiftOnCompletionRatio = lambda {|ratio|
            0.01*Math.atan(-ratio)
        }

        shiftOnDateTime = lambda {|item, datetime|
            0.001*(Time.new.to_f - DateTime.parse(datetime).to_time.to_f)/86400
        }

        shiftOnUnixtime = lambda {|item, unixtime|
            0.001*Math.log(Time.new.to_f - unixtime)
        }

        # ordering: alphabetical order

        if item["mikuType"] == "Cx22" then
            return nil if !DoNotShowUntil::isVisible(item["uuid"])
            completionRatio = Ax39::standardAx39CarrierOperationalRatio(item)
            return nil if completionRatio >= 1
            basis = item["isWork"] ? 0.93 : 0.78
            return basis + shiftOnCompletionRatio.call(completionRatio)
        end

        if item["mikuType"] == "LambdX1" then
            return 1
        end

        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::isOpenToAcknowledgement(item) ? 0.95 : nil
        end

        if item["mikuType"] == "NxOndate" then
            return 0.79 + shiftOnUnixtime.call(item, item["unixtime"])
        end

        if item["mikuType"] == "TxProject" then
            return 0.77 + shiftOnUnixtime.call(item, item["unixtime"])
        end

        if item["mikuType"] == "NxTodo" then
            if (cx22 = Cx22Mapping::itemToCx22OrNull(item)) then
                priority = PolyFunctions::listingPriorityOrNull(cx22)
                return nil if priority.nil?
                return priority + 0.001*LightSpeed::metric(item["uuid"], item["lightspeed"])
            end
            return LightSpeed::metric(item["uuid"], item["lightspeed"])
        end

        if item["mikuType"] == "NxTriage" then
            return 0.92 + shiftOnUnixtime.call(item, item["unixtime"])
        end

        if item["mikuType"] == "TxManualCountDown" then
            return 0.90
        end

        if item["mikuType"] == "Wave" then
            if item["onlyOnDays"] and !item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()) then
                return nil
            end
            mapping = {
                "ns:mandatory-today" => 0.94,
                "ns:time-important"  => 0.70,
                "ns:beach"           => 0.40
            }
            base = mapping[item["priority"]]
            return base + shiftOnDateTime.call(item, item["lastDoneDateTime"])
        end

        raise "(error: 4302a0f5-91a0-4902-8b91-e409f123d305) no priority defined for item: #{item}"
    end

    # PolyFunctions::timeBeforeNotificationsInHours(item)
    def self.timeBeforeNotificationsInHours(item)
        1
    end

    # PolyFunctions::toString(item)
    def self.toString(item)

        # order: lexicographic

        if item["mikuType"] == "Cx22" then
            return Cx22::toString(item)
        end
        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "Nx7" then
            return Nx7::toString(item)
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item)
        end
        if item["mikuType"] == "NxTriage" then
            return NxTriages::toString(item)
        end
        if item["mikuType"] == "TxProject" then
            return TxProjects::toString(item)
        end
        if item["mikuType"] == "TxManualCountDown" then
            return "(countdown) #{item["description"]}: #{item["counter"]}"
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::toStringForCatalystListing(item)
    def self.toStringForCatalystListing(item)
        if item["mikuType"] == "Cx22" then
            return Cx22::toStringForListing(item)
        end
        PolyFunctions::toString(item)
    end
end
