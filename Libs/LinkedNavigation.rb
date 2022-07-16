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
            uuids = items.map{|item| item["uuid"] }
            EditionDesk::exportAndAccessMiscItemsReadOnly(uuids)
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
        uuids = NxLink::linkedUUIDs(item["uuid"])
                    # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] } # TODO:
        LinkedNavigation::navigateMiscEntities(uuids)
    end

    # LinkedNavigation::navigateMiscEntities(uuids)
    def self.navigateMiscEntities(uuids)
        loop {
            system("clear")

            puts "lowest  datetime: #{Fx18s::getAttributeOrNull(uuids.first, "datetime")}"
            puts "highest datetime: #{Fx18s::getAttributeOrNull(uuids.last, "datetime")}"

            options = ["display all", "edition desk export all", "zoom on time period"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            
            if option == "display all" then
                loop {
                    system("clear")
                    linkeditem = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", uuids, lambda{|itemuuid| LxFunction::function("toString2", itemuuid) })
                    break if linkeditem.nil?
                    Landing::landing(linkeditem)
                }
            end

            if option == "edition desk export all" then
                EditionDesk::exportAndAccessMiscItemsReadOnly(uuids)
            end

            if option == "zoom on a time period" then
                puts "datetime1:"
                datetime1 = CommonUtils::interactiveDateTimeBuilder()
                puts "datetime2:"
                datetime2 = CommonUtils::interactiveDateTimeBuilder()
                subset = uuids.select{|uuid| 
                    datetime = Fx18s::getAttributeOrNull(uuid, "datetime")
                    datetime >= datetime1 and datetime <= datetime2 
                }
            end
        }
    end

end