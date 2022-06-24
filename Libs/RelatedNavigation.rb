class RelatedNavigation

    # RelatedNavigation::navigateItemsMonth(collectionitem, items, month)
    def self.navigateItemsMonth(collectionitem, items, month)

        if LucilleCore::askQuestionAnswerAsBoolean("individualy access #{items.size} items ? (no for edition deskting) ") then
            loop {
                system("clear")
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| LxFunction::function("toString", item) })
                return if item.nil?
                Landing::landing(item)
            }
        else
            EditionDesk::accessCollectionItemItemsPair(collectionitem, items, month)
        end
    end

    # RelatedNavigation::navigateItemsYear(collectionitem, items, year)
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
                RelatedNavigation::navigateItemsMonth(collectionitem, items.select{|item| item["datetime"].start_with?(month)}, month)
            } 
        end
    end

    # RelatedNavigation::navigate(item)
    def self.navigate(item)
        loop {
            system("clear")
            related = NxLink::related(item["uuid"])
                        .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            years = related.map{|item| item["datetime"][0, 4] }.uniq.sort
            if years.size == 1 then
                RelatedNavigation::navigateItemsYear(item, related, years.first)
                break
            end
            year = LucilleCore::selectEntityFromListOfEntitiesOrNull("year", years)
            break if year.nil?
            RelatedNavigation::navigateItemsYear(item, related.select{|item| item["datetime"].start_with?(year)}, year)
        }
    end
end
