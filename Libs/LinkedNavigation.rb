class LinkedNavigation

    # LinkedNavigation::navigateItemsMonth(collectionitem, items, month)
    def self.navigateItemsMonth(collectionitem, items, month)

        if LucilleCore::askQuestionAnswerAsBoolean("individualy access #{items.size} items ? (no for edition deskting) ") then
            loop {
                system("clear")
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| LxFunction::function("toString", item) })
                return if item.nil?
                Landing::landing(item, isSearchAndSelect = false)
            }
        else
            uuids = items.map{|item| item["uuid"] }
            puts "Code to be written (8cfc7215-743a-418f-9f92-9e40c22f27ab)"
            exit
        end
    end

    # LinkedNavigation::navigateItemsYear(collectionitem, items, year)
    def self.navigateItemsYear(collectionitem, items, year)
        if items.size < 50 then
            loop {
                system("clear")
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| LxFunction::function("toString", item) })
                return if item.nil?
                Landing::landing(item, isSearchAndSelect = false)
            }
        else
            loop {
                system("clear")
                months = items.map{|item| item["datetime"][0, 7] }.uniq.sort
                month = LucilleCore::selectEntityFromListOfEntitiesOrNull("month", months)
                break if month.nil?
                LinkedNavigation::navigateItemsMonth(collectionitem, items.select{|item| item["datetime"].start_with?(month)}, month)
            } 
        end
    end

    # LinkedNavigation::navigate(item)
    def self.navigate(item)
        uuids = NetworkLinks::linkeduuids(item["uuid"])
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        LinkedNavigation::navigateMiscEntities(uuids)
    end

    # LinkedNavigation::navigateMiscEntities(uuids)
    def self.navigateMiscEntities(uuids)
        loop {
            system("clear")

            puts "lowest  datetime: #{Fx18Attributes::getJsonDecodeOrNull(uuids.first, "datetime")}"
            puts "highest datetime: #{Fx18Attributes::getJsonDecodeOrNull(uuids.last, "datetime")}"

            options = ["display all", "edition desk export all", "zoom on time period"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            
            if option == "display all" then
                loop {
                    system("clear")
                    lb  = lambda{|itemuuid| LxFunction::function("toString", Fx256::getAliveProtoItemOrNull(itemuuid)) }
                    linkeditemuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", uuids, lb)
                    break if linkeditemuuid.nil?
                    item = Fx256::getAliveProtoItemOrNull(linkeditemuuid)
                    break if item.nil?
                    Landing::landing(item, isSearchAndSelect = false)
                }
            end

            if option == "edition desk export all" then
                puts "Code to be written (8cfc7215-743a-418f-9f92-9e40c22f27ab)"
                exit
            end

            if option == "zoom on a time period" then
                puts "datetime1:"
                datetime1 = CommonUtils::interactiveDateTimeBuilder()
                puts "datetime2:"
                datetime2 = CommonUtils::interactiveDateTimeBuilder()
                subset = uuids.select{|uuid| 
                    datetime = Fx18Attributes::getJsonDecodeOrNull(uuid, "datetime")
                    datetime >= datetime1 and datetime <= datetime2 
                }
            end
        }
    end
end
