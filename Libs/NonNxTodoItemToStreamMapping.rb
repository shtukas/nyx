
class NonNxTodoItemToStreamMapping

    # NonNxTodoItemToStreamMapping::set(uuid, streamuuid)
    def self.set(uuid, streamuuid)
        puts "NonNxTodoItemToStreamMapping::set(#{uuid}, #{streamuuid})"
        Lookups::commit("NonNxTodoItemToStreamMapping", uuid, streamuuid)
    end

    # NonNxTodoItemToStreamMapping::unset(uuid)
    def self.unset(uuid)
        Lookups::destroy("NonNxTodoItemToStreamMapping", uuid)
    end

    # NonNxTodoItemToStreamMapping::getOrNull(item)
    def self.getOrNull(item)
        if item["mikuType"] == "NxStreamFirstItem" then
            item = item["todo"]
        end
        Lookups::getValueOrNull("NonNxTodoItemToStreamMapping", item["uuid"])
    end

    # NonNxTodoItemToStreamMapping::toStringSuffix(item)
    def self.toStringSuffix(item)
        streamuuid = NonNxTodoItemToStreamMapping::getOrNull(item)
        return "" if streamuuid.nil?
        stream = NxStreams::getItemOfNull(streamuuid)
        return "" if stream.nil?
        " (stream: #{stream["description"]})"
    end

    # NonNxTodoItemToStreamMapping::interactiveProposalToSetMapping(item)
    def self.interactiveProposalToSetMapping(item)
        if item["mikuType"] == "NxTodo" then
            puts "Cannot apply NonNxTodoItemToStreamMapping to a NxTodo"
            LucilleCore::pressEnterToContinue()
            return
        end
        if item["mikuType"] == "NxStream" then
            puts "Cannot apply NonNxTodoItemToStreamMapping to a NxStream"
            LucilleCore::pressEnterToContinue()
            return
        end
        stream = NxStreams::interactivelySelectOneOrNull()
        return if stream.nil?
        NonNxTodoItemToStreamMapping::set(item["uuid"], stream["uuid"])
    end
end
