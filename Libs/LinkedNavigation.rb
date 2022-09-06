class LinkedNavigation

    # LinkedNavigation::navigateItemsMonth(collectionitem, items, month)
    def self.navigateItemsMonth(collectionitem, items, month)

        if LucilleCore::askQuestionAnswerAsBoolean("individualy access #{items.size} items ? (no for edition deskting) ") then
            loop {
                system("clear")
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| PolyFunctions::toString(item) })
                return if item.nil?
                PolyPrograms::landing(item)
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
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| PolyFunctions::toString(item) })
                return if item.nil?
                PolyPrograms::landing(item)
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

    # LinkedNavigation::navigateItem(item)
    def self.navigateItem(item)
        entities = NetworkLinks::linkedEntities(item["uuid"])
        if entities.empty? then
            puts "I could not find linked entities for item: `#{PolyFunctions::toString(item)}`"
            LucilleCore::pressEnterToContinue()
            return
        end 
        entities = entities.sort{ |e1, e2| e1["datetime"] <=> e2["datetime"] }
        LinkedNavigation::navigateGivenEntities(entities)
    end

    # LinkedNavigation::navigateGivenEntities(entities)
    def self.navigateGivenEntities(entities)
        loop {
            system("clear")

            puts "lowest  datetime: #{entities.first["datetime"]}"
            puts "highest datetime: #{entities.last["datetime"]}"

            options = ["list all", "desk export all", "zoom on time period"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            
            if option == "list all" then
                loop {
                    system("clear")
                    entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", entities, lambda{|entity| PolyFunctions::toString(entity) })
                    break if entity.nil?
                    PolyPrograms::landing(entity)
                }
            end

            if option == "desk export all" then
                puts "Code to be written (8cfc7215-743a-418f-9f92-9e40c22f27ab)"
                exit
            end

            if option == "zoom on a time period" then
                puts "datetime1:"
                datetime1 = CommonUtils::interactiveDateTimeBuilder()
                puts "datetime2:"
                datetime2 = CommonUtils::interactiveDateTimeBuilder()
                entities = entities
                                .select{|entity| 
                                    datetime = entity["datetime"]
                                    datetime >= datetime1 and datetime <= datetime2 
                                }
                LinkedNavigation::navigateGivenEntities(entities)
            end
        }
    end
end
