
# encoding: UTF-8

class Nyx

    # Nyx::program()
    def self.program()
        loop {
            system("clear")

            operations = [
                "search (interactive)",
                "search (classic)",
                "display nodes in timeline order",
                "make new entity",
                "special ops"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (interactive)" then
                Search::interativeInterface()
            end
            if operation == "search (classic)" then
                Search::classicInterface()
            end
            if operation == "display nodes in timeline order" then
                NxDataNodes::items()
                    .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                    .each{|item| puts NxDataNodes::toString(item) }
                LucilleCore::pressEnterToContinue()
            end
            if operation == "make new entity" then
                item = NyxNetwork::interactivelyMakeNewOrNull()
                next if item.nil?
                LxAction::action("landing", item)
            end
            if operation == "special ops" then
                specialOps = [
                    "game: correcting datetimes",
                ]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("op", specialOps)
                if op == "game: correcting datetimes" then

                    markHasHavingBeenDatetimeChecked = lambda{|item|
                        XCache::setFlag("4636773d-6aa6-4835-b740-0415e4f9149e:#{item["uuid"]}", true)
                    }

                    hasBeenDateTimeChecked = lambda{|item|
                        XCache::getFlag("4636773d-6aa6-4835-b740-0415e4f9149e:#{item["uuid"]}")
                    }

                    NxDataNodes::getItemsFromTheBiggestYearMonthGame1Edition()
                        .each{|item|
                            next if hasBeenDateTimeChecked.call(item)
                            LxAction::action("landing", item)
                            markHasHavingBeenDatetimeChecked.call(item)
                        }

                end
            end
        }
    end
end
