class CircleNavigation

    # CircleNavigation::navigateItemsMonth(collectionitem, items, month)
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

    # CircleNavigation::navigateItemsYear(collectionitem, items, year)
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
                CircleNavigation::navigateItemsMonth(collectionitem, items.select{|item| item["datetime"].start_with?(month)}, month)
            } 
        end
    end

    # CircleNavigation::navigate(item)
    def self.navigate(item)
        loop {
            system("clear")
            children = NxArrow::children(item["uuid"])
                        .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            years = children.map{|item| item["datetime"][0, 4] }.uniq.sort
            if years.size == 1 then
                CircleNavigation::navigateItemsYear(item, children, years.first)
                break
            end
            year = LucilleCore::selectEntityFromListOfEntitiesOrNull("year", years)
            break if year.nil?
            CircleNavigation::navigateItemsYear(item, children.select{|item| item["datetime"].start_with?(year)}, year)
        }
    end
end
