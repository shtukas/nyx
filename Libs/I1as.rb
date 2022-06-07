
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

    # I1as::manageI1as(item, i1as) # item ( possibly updated, commited)
    def self.manageI1as(item, i1as)
        #nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), item["uuid"])
        #next if nx111.nil?
        #puts JSON.pretty_generate(nx111)
        #if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
        #    item["iam"] = nx111
        #    Librarian::commit(item)
        #end

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["add new", "replace", "remove", "show item json"])
        return item if option.nil?
        if option == "add new" then
            nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMaking(), item["uuid"])
            return item if nx111.nil?
            item["i1as"] << nx111
            Librarian::commit(item)
            return item
        end
        if option == "replace" then
            nx111 = I1as::selectOneNx111OrNull(i1as)
            return item if nx111.nil?
            nx111v2 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMaking(), item["uuid"])
            puts JSON.pretty_generate(nx111v2)
            item["i1as"] = item["i1as"].select{|nx| nx["uuid"] != nx111["uuid"] } + [ nx111v2 ]
            Librarian::commit(item)
            return item
        end
        if option == "remove" then
            nx111 = I1as::selectOneNx111OrNull(i1as)
            return item if nx111.nil?
            item["i1as"] = item["i1as"].select{|nx| nx["uuid"] != nx111["uuid"] }
            Librarian::commit(item)
            return item
        end
        if option == "show item json" then
            nx111 = I1as::selectOneNx111OrNull(i1as)
            return item if nx111.nil?
            puts JSON.pretty_generate(nx111)
            LucilleCore::pressEnterToContinue()
            return item
        end
        raise "(error: f750ebaf-78aa-443c-9d49-1de7bf9f98a5)"
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
