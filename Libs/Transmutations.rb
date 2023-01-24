
class Transmutations

    # Transmutations::transmute1(item, sourceType, targetType)
    def self.transmute1(item, sourceType, targetType)

        if sourceType == "NxOndate" and targetType == "NxTodo" then
            uuid1 = item["uuid"]
            wtc = NxWTimeCommitments::interactivelySelectItem()
            tcPos = NxWTimeCommitments::nextPositionForItem(wtc["uuid"])
            item["uuid"] = SecureRandom.uuid
            item["mikuType"] = "NxTodo"
            item["tcId"] = wtc["uuid"]
            item["tcPos"] = tcPos
            NxTodosIO::commit(item)
            NxOndates::destroy(uuid1)
            return
        end

        if sourceType == "NxTop" and targetType == "NxOndate" then
            uuid1 = item["uuid"]
            item["uuid"] = SecureRandom.uuid
            item["mikuType"] = "NxTodo"
            item["datetime"] = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
            NxOndates::commit(item)
            NxTops::destroy(uuid1)
            return
        end

        if sourceType == "NxTop" and targetType == "NxTodo" then
            uuid1 = item["uuid"]
            puts "description: #{item["description"].green}"
            d = LucilleCore::askQuestionAnswerAsString("description (empty to confirm existing): ")
            if d == "" then
                description = item["description"]
            else
                description = d
            end
            wtc = NxWTimeCommitments::interactivelySelectItem()
            tcPos = NxWTimeCommitments::interactivelyDecideProjectPosition(wtc["uuid"])
            item["uuid"] = SecureRandom.uuid
            item["description"] = description
            item["mikuType"] = "NxTodo"
            item["tcId"] = wtc["uuid"]
            item["tcPos"] = tcPos
            NxTodosIO::commit(item)
            NxTops::destroy(uuid1)
            return
        end

        if sourceType == "NxTriage" and targetType == "NxTodo" then
            uuid1 = item["uuid"]
            puts "description: #{item["description"].green}"
            d = LucilleCore::askQuestionAnswerAsString("description (empty to confirm existing): ")
            if d == "" then
                description = item["description"]
            else
                description = d
            end
            wtc = NxWTimeCommitments::interactivelySelectItem()
            tcPos = NxWTimeCommitments::interactivelyDecideProjectPosition(wtc["uuid"])
            item["uuid"] = SecureRandom.uuid
            item["description"] = description
            item["mikuType"] = "NxTodo"
            item["tcId"] = wtc["uuid"]
            item["tcPos"] = tcPos
            NxTodosIO::commit(item)
            NxTriages::destroy(uuid1)
            return
        end

        puts "transmutation: I do not know how to transmute '#{sourceType}' to '#{targetType}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutations::interactivelySelectTargetTypeOrNull(item)
    def self.interactivelySelectTargetTypeOrNull(item)
        if item["mikuType"] == "NxOndate" then
            targetTypes = ["NxTodo"]
            return LucilleCore::selectEntityFromListOfEntitiesOrNull("targetType", targetTypes)
        end
        if item["mikuType"] == "NxTop" then
            targetTypes = ["NxTodo", "NxOndate"]
            return LucilleCore::selectEntityFromListOfEntitiesOrNull("targetType", targetTypes)
        end
        nil
    end

    # Transmutations::transmute2(item)
    def self.transmute2(item)
        targetType = Transmutations::interactivelySelectTargetTypeOrNull(item)
        return if targetType.nil?
        Transmutations::transmute1(item, item["mikuType"], targetType)
    end

end
