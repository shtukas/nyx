
# encoding: UTF-8

class Transmutation

    # Transmutation::interactivelyNx50ToNyx(todo) # Nx100
    def self.interactivelyNx50ToNyx(todo)

        description = todo["description"]
        i1as = todo["i1as"]


        flavourMaker = lambda {|i1as|
            if i1as.all?{|nx111| nx111["type"] == "primitive-file" } then
                return {
                    "type" => "pure-data"
                }
            end
            Nx102Flavor::interactivelyCreateNewFlavour()
        }

        flavour = flavourMaker.call(i1as)

        uuid       = SecureRandom.uuid
        unixtime   = todo["unixtime"]
        datetime   = todo["datetime"]

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "i1as"        => i1as,
            "flavour"     => flavour
        }
        Librarian::commit(item)
        item

    end

    # Transmutation::floatToNyx(float)
    def self.floatToNyx(float)
        puts "(60fbc884-301f-44d1-a03e-66e824c4e2a0: This has not been implemented, need re-implementation after refactoring)"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutation1(object, source, target)
    # source: "TxDated" (dated) | "TxTodo" | "TxFloat" (float)
    # target: "TxDated" (dated) | "TxTodo" | "TxFloat" (float)
    def self.transmutation1(object, source, target)

        if source == "TxDated" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxTodo"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxDated" and target == "TxProject" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxProject"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            object["mikuType"] = "TxFloat"
            object["universe"] = Multiverse::interactivelySelectUniverse()
            Librarian::commit(object)
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxDated"
            object["datetime"] = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxFloat" and target == "TxProject" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxProject"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxTodo"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxProject" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxTodo"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxProject" and target == "TxFloat" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxFloat"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxTodo" and target == "TxProject" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxProject"
            object["universe"] = universe
            Librarian::commit(object)
            return
        end

        if source == "TxTodo" and target == "Nx100" then
            nx100 = object.clone
            nx100["uuid"] = SecureRandom.uuid
            nx100["mikuType"] = "Nx100"
            nx100["flavour"] = Nx102Flavor::interactivelyCreateNewFlavour()
            Librarian::commit(nx100)
            TxTodos::destroy(object["uuid"])
            Nx100s::landing(nx100)
            return
        end

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutation2(object, source)
    def self.transmutation2(object, source)
        target = Transmutation::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        Transmutation::transmutation1(object, source, target)
    end

    # Transmutation::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = ["TxFloat", "TxProject", "TxDated", "TxTodo" ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", options)
        return nil if option.nil?
        option
    end
end
