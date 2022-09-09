class PolyFunctions

    # PolyFunctions::_check(item, functionname)
    def self._check(item, functionname)
        if item.nil?  then
            raise "(error: d366d408-93a1-4e91-af92-c115e88c501f) null item sent to #{functionname}"
        end

        if item["mikuType"].nil? then
            puts "Objects sent to a poly function should have a mikuType attribute."
            puts "function name: #{functionname}"
            puts "item: #{JSON.pretty_generate(item)}"
            puts "Aborting."
            raise "(error: f74385d4-5ece-4eae-8a09-90d3a5e0f120)"
        end
    end

    # PolyFunctions::genericDescription(item)
    def self.genericDescription(item)
        PolyFunctions::_check(item, "PolyFunctions::genericDescription")

        if item["mikuType"] == "CxAionPoint" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxDx8Unit" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxFile" then
           return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxText" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxUniqueString" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxUrl" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "DxAionPoint" then
            return item["description"]
        end
        if item["mikuType"] == "DxFile" then
            return (item["description"] ? item["description"] : "DxFile: #{item["nhash"]}")
        end
        if item["mikuType"] == "DxLine" then
            return item["line"]
        end
        if item["mikuType"] == "DxText" then
            return item["description"]
        end
        if item["mikuType"] == "DxUniqueString" then
            return item["description"]
        end
        if item["mikuType"] == "DxUrl" then
            return item["url"]
        end
        if item["mikuType"] == "InboxItem" then
            return item["description"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
        if item["mikuType"] == "NxCollection" then
            return item["description"]
        end
        if item["mikuType"] == "NxConcept" then
            return item["description"]
        end
        if item["mikuType"] == "NxEntity" then
            return item["description"]
        end
        if item["mikuType"] == "NxEvent" then
            return item["description"]
        end
        if item["mikuType"] == "NxIced" then
            return item["description"]
        end
        if item["mikuType"] == "NxPerson" then
            return item["name"]
        end
        if item["mikuType"] == "NxTask" then
            return item["description"]
        end
        if item["mikuType"] == "NxTimeline" then
            return item["description"]
        end
        if item["mikuType"] == "TxFloat" then
            return item["description"]
        end
        if item["mikuType"] == "TxThread" then
            return item["description"]
        end
        if item["mikuType"] == "TxTimeCommitmentProject" then
            return item["description"]
        end
        if item["mikuType"] == "TopLevel" then
            firstline = TopLevel::getFirstLineOrNull(item)
            return (firstline ? firstline : "(no generic-description)")
        end
        if item["mikuType"] == "TxDated" then
            return item["description"]
        end
        if item["mikuType"] == "Wave" then
            return item["description"]
        end

        puts "I do not know how to PolyFunctions::genericDescription(#{JSON.pretty_generate(item)})"
        raise "(error: 475225ec-74fe-4614-8664-a99c1b2c9916)"
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        PolyFunctions::_check(item, "PolyFunctions::toString")
        if item["mikuType"] == "fitness1" then
            return item["announce"]
        end
        if item["mikuType"] == "DxAionPoint" then
            return DxAionPoint::toString(item)
        end
        if item["mikuType"] == "CxFile" then
            return CxFile::toString(item)
        end
        if item["mikuType"] == "CxText" then
            return CxText::toString(item)
        end
        if item["mikuType"] == "CxUniqueString" then
            return CxUniqueString::toString(item)
        end
        if item["mikuType"] == "CxUrl" then
            return CxUrl::toString(item)
        end
        if item["mikuType"] == "DxFile" then
            return DxFile::toString(item)
        end
        if item["mikuType"] == "DxLine" then
            return DxLine::toString(item)
        end
        if item["mikuType"] == "DxText" then
            return DxText::toString(item)
        end
        if item["mikuType"] == "DxUniqueString" then
            return DxUniqueString::toString(item)
        end
        if item["mikuType"] == "DxUrl" then
            return DxUrl::toString(item)
        end
        if item["mikuType"] == "InboxItem" then
            return InboxItems::toString(item)
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBall.v2" then
            return item["description"]
        end
        if item["mikuType"] == "NxCollection" then
            return NxCollections::toString(item)
        end
        if item["mikuType"] == "NxConcept" then
            return NxConcepts::toString(item)
        end
        if item["mikuType"] == "NxEntity" then
            return NxEntities::toString(item)
        end
        if item["mikuType"] == "NxEvent" then
            return NxEvents::toString(item)
        end
        if item["mikuType"] == "NxIced" then
            return NxIceds::toString(item)
        end
        if item["mikuType"] == "NxPerson" then
            return NxPersons::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxTimeline" then
            return NxTimelines::toString(item)
        end
        if item["mikuType"] == "TxFloat" then
            return TxFloats::toString(item)
        end
        if item["mikuType"] == "TxTimeCommitmentProject" then
            return TxTimeCommitmentProjects::toString(item)
        end
        if item["mikuType"] == "TopLevel" then
            return TopLevel::toString(item)
        end
        if item["mikuType"] == "TxDated" then
            return TxDateds::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end

        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::edit(item) # item
    def self.edit(item)

        puts "PolyFunctions::edit(#{JSON.pretty_generate(item)})"

        # order: by mikuType

        if item["mikuType"] == "CxAionPoint" then
            return CxAionPoint::edit(item)
        end

        if item["mikuType"] == "CxText" then
            return CxText::edit(item)
        end

        if item["mikuType"] == "DxAionPoint" then
            return DxAionPoint::edit(item)
        end

        if item["mikuType"] == "DxText" then
            text = CommonUtils::editTextSynchronously(item["text"])
            DxF1::setAttribute2(item["uuid"], "text", text)
            return TheIndex::getItemOrNull(item["uuid"])
        end

        if item["mikuType"] == "TopLevel" then
            return TopLevel::edit(item)
        end

        if Iam::isNx112Carrier(item) then
            if item["nx112"] then
                targetItem = TheIndex::getItemOrNull(item["nx112"])
                puts "target data carrier: #{JSON.pretty_generate(targetItem)}"
                PolyFunctions::edit(targetItem)
                return item
            else
                puts "This item doesn't have a Nx112 attached to it"
                status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
                if status then
                    PolyActions::editDescription(item)
                    return TheIndex::getItemOrNull(item["uuid"])
                else
                    return item
                end
            end
        end
 
        puts "I do not know how to PolyFunctions::edit(#{JSON.pretty_generate(item)})"
        raise "(error: 628167a9-f6c9-4560-bdb0-4b0eb9579c86)"
    end

    # PolyFunctions::timeBeforeNotificationsInHours(item)
    def self.timeBeforeNotificationsInHours(item)
        1
    end

    # PolyFunctions::bankAccounts(item)
    def self.bankAccounts(item)

        decideOwnersUUIDs = lambda {|item|

            ownersuuids = OwnerItemsMapping::elementuuidToOwnersuuidsCached(item["uuid"])
            if ownersuuids.size > 0 then
                return ownersuuids
            end

            key = "bb9bf6c2-87c4-4fa1-a8eb-21c0b3c67c61:#{item["uuid"]}"
            uuid = XCache::getOrNull(key)
            if uuid == "null" then
                return []
            end
            if uuid then
                return [uuid]
            end
            puts "This is important, pay attention. We need an owner for this item, for the accounting."
            LucilleCore::pressEnterToContinue()
            ox = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
            if ox then
                XCache::set(key, ox["uuid"])
                SystemEvents::broadcast({
                    "mikuType" => "XCacheSet",
                    "key"      => key,
                    "value"    => ox["uuid"]
                })
                return [ox["uuid"]]
            else
                XCache::set(key, "null")
                SystemEvents::broadcast({
                    "mikuType" => "XCacheSet",
                    "key"      => key,
                    "value"    => "null"
                })
                return []
            end
        }

        if item["mikuType"] == "TxTimeCommitmentProject" then
            return [item["uuid"]]
        end

        [item["uuid"]] + decideOwnersUUIDs.call(item)
    end

    # PolyFunctions::foxTerrierAtItem(item)
    def self.foxTerrierAtItem(item)
        loop {
            system("clear")
            puts "------------------------------".green
            puts "Fox Terrier Or Null (`select`)".green
            puts "------------------------------".green
            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)
            entities = NetworkLinks::linkedEntities(item["uuid"])
            if entities.size > 0 then
                puts ""
                if entities.size < 200 then
                    entities
                        .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                        .each{|entity|
                            indx = store.register(entity, false)
                            puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
                        }
                else
                    puts "(... many entities, use `navigation` ...)"
                end
            end

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return nil if input == ""

            if input == "select" then
                return item
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                return if entity.nil?
                resultOpt = PolyFunctions::foxTerrierAtItem(entity)
                return resultOpt if resultOpt
            end
        }
    end
end
