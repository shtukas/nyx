
# encoding: UTF-8

class Transmutation

    # Transmutation::interactivelyNx50ToNyx(todo) # Nx100
    def self.interactivelyNx50ToNyx(todo)
        description = todo["description"]

        flavourMaker = lambda {|nx111|
            if nx111["type"] == "primitive-file" then
                return {
                    "type" => "pure-data"
                }
            end
            Nx102Flavor::interactivelyCreateNewFlavour()
        }

        uuid       = SecureRandom.uuid
        unixtime   = todo["unixtime"]
        datetime   = todo["datetime"]

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "nx111"       => todo["nx111"]
        }
        Librarian::commit(item)
        item

    end

    # Transmutation::transmutation1(object, source, target)
    # source: "TxDated" (dated) | "TxTodo" | "TxFloat" (float)
    # target: "TxDated" (dated) | "TxTodo" | "TxFloat" (float)
    def self.transmutation1(object, source, target)

        if source == "TxDated" and target == "TxTodo" then
            object["mikuType"] = "TxTodo"
            Librarian::commit(object)
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            object["mikuType"] = "TxFloat"
            Librarian::commit(object)
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            object["mikuType"] = "TxDated"
            object["datetime"] = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
            Librarian::commit(object)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            object["mikuType"] = "TxTodo"
            Librarian::commit(object)
            return
        end

        if source == "TxTodo" and target == "Nx100" then
            nx100 = object.clone
            nx100["uuid"] = SecureRandom.uuid
            nx100["mikuType"] = "Nx100"
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
        options = ["TxFloat", "TxDated", "TxTodo" ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", options)
        return nil if option.nil?
        option
    end
end
