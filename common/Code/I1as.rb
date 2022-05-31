
# encoding: UTF-8

class I1as

    # I1as::toStringShort(i1as)
    def self.toStringShort(i1as)
        if i1as.size == 0 then
            return "no nx111 found"
        end
        if i1as.size == 1 then
            return i1as[0]["type"]
        end
        "multiple nx111s"
    end

    # I1as::manageI1as(item, i1as)
    def self.manageI1as(item, i1as)
        #nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), item["uuid"])
        #next if nx111.nil?
        #puts JSON.pretty_generate(nx111)
        #if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
        #    item["iam"] = nx111
        #    Librarian::commit(item)
        #end

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["edit existing", "add", "remove"])
        return if option.nil?
        if option == "edit existing" then
            puts "(warning: 06036d599) code not yet written"
            LucilleCore::pressEnterToContinue()
        end
        if option == "add" then
            puts "(warning: 5e8d-45e0-bed3) code not yet written"
            LucilleCore::pressEnterToContinue()
        end
        if option == "remove" then
            puts "(warning: 8faca9821a0) code not yet written"
            LucilleCore::pressEnterToContinue()
        end
    end

    # I1as::selectOneNx111OrNull(i1as)
    def self.selectOneNx111OrNull(i1as)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx111", i1as, lambda{|nx111| "#{nx111["uuid"][0, 4]} #{nx111["type"]}" })
    end

    # I1as::selectOneNx111OrNullAutoSelectIfOne(i1as)
    def self.selectOneNx111OrNullAutoSelectIfOne(i1as)
        if i1as.size == 1 then
            return i1as[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx111", i1as, lambda{|nx111| "#{nx111["uuid"][0, 4]} #{nx111["type"]}" })
    end
end
