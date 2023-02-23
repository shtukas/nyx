class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item)
    def self.itemsToBankingAccounts(item)
        accounts = []

        if item["mikuType"] == "NxBoard" then
            accounts << {
                "description" => item["description"],
                "number"      => item["uuid"]
            }
            accounts << {
                "description" => "capsule: #{item["capsule"]}",
                "number"      => item["capsule"]
            }
            return accounts
        end

        if item["mikuType"] == "NxBoardItem" then
            accounts << {
                "description" => "[self]",
                "number"      => item["uuid"]
            }
            boarduuid = item["boarduuid"]
            board = NxBoards::getItemOfNull(boarduuid)
            extraAccounts = PolyFunctions::itemsToBankingAccounts(board)
            accounts = accounts + extraAccounts
            return accounts
        end

        # scheduler1 "d36d653e-80e0-4141-b9ff-f26197bbce2b" monitors Waves::leisureItems() which are exactly the Wave priority:ns:leisure items
        if item["mikuType"] == "Wave" and item["priority"] == "ns:leisure" then
            accounts << {
                "description" => "scheduler1 (d3)",
                "number"      => "d36d653e-80e0-4141-b9ff-f26197bbce2b"
            }
        end

        # scheduler1 "cfad053c-bb83-4728-a3c5-4fb357845fd9" monitors the NxHeads::listingItems() is are the NxHead items
        if item["mikuType"] == "NxHead" then
            accounts << {
                "description" => "scheduler1 (cf)",
                "number"      => "cfad053c-bb83-4728-a3c5-4fb357845fd9"
            }
        end

        accounts << {
            "description" => "[self]",
            "number"      => item["uuid"]
        }

        board = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
        if board then
            extraAccounts = PolyFunctions::itemsToBankingAccounts(board)
            accounts = accounts + extraAccounts
        end

        accounts
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxBoardItem" then
            return NxBoardItems::toString(item)
        end
        if item["mikuType"] == "NxNode" then
            return NxNodes::toString(item)
        end
        if item["mikuType"] == "NxOpen" then
            return NxOpens::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxTail" then
            return NxTails::toString(item)
        end
        if item["mikuType"] == "NxHead" then
            return NxHeads::toString(item)
        end
        if item["mikuType"] == "NxTop" then
            return NxTops::toString(item)
        end
        if item["mikuType"] == "TxManualCountDown" then
            return "(countdown) #{item["description"]}: #{item["counter"]}"
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::toStringForSearchListing(item)
    def self.toStringForSearchListing(item)
        if item["mikuType"] == "Wave" then
            return Waves::toStringForSearch(item)
        end
        PolyFunctions::toString(item)
    end
end
