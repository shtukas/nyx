
# encoding: UTF-8

class NyxAdapter

    # NyxAdapter::interactivelyNx50ToNyx(todo) # Nx100
    def self.interactivelyNx50ToNyx(todo)

        description = todo["description"]
        iAmValue = todo["iam"]


        flavourMaker = lambda {|iAmValue|
            if iAmValue[0] == "primitive-file"  then
                return {
                    "type" => "pure-data"
                }
            end
            Nx102Flavor::interactivelyCreateNewFlavour()
        }

        flavour = flavourMaker.call(iAmValue)

        uuid       = SecureRandom.uuid
        unixtime   = todo["unixtime"]
        datetime   = todo["datetime"]

        item = {
            "uuid"        => uuid,
            "mikuType"    => "Nx100",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "iam"         => iAmValue,
            "flavour"     => flavour
        }
        Librarian6Objects::commit(item)
        item

    end

    # NyxAdapter::floatToNyx(float)
    def self.floatToNyx(float)
        puts "(60fbc884-301f-44d1-a03e-66e824c4e2a0: This has not been implemented, need re-implementation after refactoring)"
        LucilleCore::pressEnterToContinue()
    end
end
