class PolyFunctions

    # ordering: alphabetical

    # PolyFunctions::bankAccountsForItem(item)
    def self.bankAccountsForItem(item)
        accounts = []
        accounts << item["uuid"]
        if item["cx22"] then
            cx22 = Cx22::getOrNull(item["cx22"])
            if cx22 then
                accounts << cx22["uuid"]
            end
        end
        if cx23 = Cx22::getCx23ForItemuuidOrNull(item["uuid"]) then
            cx22 = Cx22::getOrNull(cx23["groupuuid"])
            if cx22 then
                accounts << cx22["uuid"]
            end
        end
        accounts.uniq
    end

    # PolyFunctions::edit(item) # item
    def self.edit(item)

        puts "PolyFunctions::edit(#{JSON.pretty_generate(item)})"

        # order: by mikuType

        if item["mikuType"] == "NxCatalistLine1" then
            puts "NxCatalistLine1 doesn't implement edit"
            LucilleCore::pressEnterToContinue()
            return
        end

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

    # PolyFunctions::genericDescriptionOrNull(item)
    def self.genericDescriptionOrNull(item)

        # ordering: alphabetical order

        if item["mikuType"] == "InboxItem" then
            return item["description"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
        if item["mikuType"] == "NxCatalistLine1" then
            return item["line"]
        end
        if item["mikuType"] == "NxIced" then
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
        if item["mikuType"] == "TxThread" then
            return item["description"]
        end
        if item["mikuType"] == "Wave" then
            return item["description"]
        end
        return nil
    end

    # PolyFunctions::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        item = Waves::getOrNull(uuid)
        return item if item

        item = NxCatalistLine1::getItemOrNull(uuid)
        return item if item

        item = NxTodos::getItemOrNull(uuid)
        return item if item

        item = Cx22::getOrNull(uuid)
        return item if item

        # We keep this one for last, because it's slow
        item = Nx7::itemOrNull(uuid)
        return item if item

        nil
    end

    # PolyFunctions::listingPriorityOrNull(item)
    # We return a null value when the item should not be displayed
    def self.listingPriorityOrNull(item) # Float between 0 and 1

        # NxAnniversary                 0.95
        # Wave "time-critical"          0.90
        # Cx22 "isPriority" = true      0.80
        # TxManualCountDown             0.75
        # Wave "time-aware"             0.70
        # Cx22 "isPriority" = false     0.60
        # Wave "non-important"          0.50
        # NxTodo                        0.40

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
            completionRatio = Ax39::completionRatioCached(item["ax39"], item["uuid"])
            return nil if completionRatio >= 1
            base = item["isPriority"] ? 0.80 : 0.60
            return base + shiftOnCompletionRatio.call(completionRatio)
        end

        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::isOpenToAcknowledgement(item) ? 0.95 : nil
        end

        if item["mikuType"] == "NxCatalistLine1" then
            return 1
        end

        if item["mikuType"] == "NxTodo" then
            return NxTodos::listingPriorityOrNull(item)
        end

        if item["mikuType"] == "TxManualCountDown" then
            return 0.90
        end

        if item["mikuType"] == "Wave" then
            if item["onlyOnDays"] and !item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()) then
                return nil
            end
            mapping = {
                "time-critical" => 0.90,
                "time-aware"    => 0.70,
                "non-important" => 0.50
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
            return Cx22::toString1(item)
        end
        if item["mikuType"] == "Nx7" then
            return Nx7::toString(item)
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxCatalistLine1" then
            return "(line) #{item["line"]}"
        end
        if item["mikuType"] == "NxBall.v2" then
            return item["description"]
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item)
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

    # PolyFunctions::toStringForListing(item)
    def self.toStringForListing(item)
        if item["mikuType"] == "Cx22" then
            return Cx22::toStringWithDetails(item)
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toStringForListing(item)
        end
        PolyFunctions::toString(item)
    end
end
