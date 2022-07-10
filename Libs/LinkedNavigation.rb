class LinkedNavigation

    # LinkedNavigation::navigateItemsMonth(collectionitem, items, month)
    def self.navigateItemsMonth(collectionitem, items, month)

        if LucilleCore::askQuestionAnswerAsBoolean("individualy access #{items.size} items ? (no for edition deskting) ") then
            loop {
                system("clear")
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| LxFunction::function("toString", item) })
                return if item.nil?
                Landing::landing(item)
            }
        else
            EditionDesk::exportAndAccessMiscItemsReadOnly(collectionitem, items, month)
        end
    end

    # LinkedNavigation::navigateItemsYear(collectionitem, items, year)
    def self.navigateItemsYear(collectionitem, items, year)
        if items.size < 50 then
            loop {
                system("clear")
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| LxFunction::function("toString", item) })
                return if item.nil?
                Landing::landing(item)
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
        entities = NxLink::linkedItems(item["uuid"])
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        LinkedNavigation::navigateMiscEntities(entities)
    end

    # LinkedNavigation::navigateMiscEntities(entities)
    def self.navigateMiscEntities(entities)
        loop {
            system("clear")

            puts "lowest  datetime: #{entities.first["datetime"]}"
            puts "highest datetime: #{entities.last["datetime"]}"

            options = ["display all", "edition desk export all", "zoom on time period"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            
            if option == "display all" then
                loop {
                    system("clear")
                    linkeditem = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", entities, lambda{|item| LxFunction::function("toString", item) })
                    break if linkeditem.nil?
                    Landing::landing(linkeditem)
                }
            end

            if option == "edition desk export all" then
                EditionDesk::exportAndAccessMiscItemsReadOnly(entities)
            end

            if option == "zoom on a time period" then
                puts "datetime1:"
                datetime1 = CommonUtils::interactiveDateTimeBuilder()
                puts "datetime2:"
                datetime2 = CommonUtils::interactiveDateTimeBuilder()
                subset = entities.select{|ix| ix["datetime"] >= datetime1 and ix["datetime"] <= datetime2 }
            end
        }
    end

end
