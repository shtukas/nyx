
# encoding: UTF-8

class NyxNodePayloads

    # NyxNodePayloads::payloadTypes()
    def self.payloadTypes()
        ["nyx-directory"]
    end

    # NyxNodePayloads::interactivelySelectNyxPayloadType()
    def self.interactivelySelectNyxPayloadType()
        types = NyxNodePayloads::payloadTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("payload type", types)
    end

    # NyxNodePayloads::issuePayload(uuid) # payload string
    def self.issuePayload(uuid)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        payloadType = NyxNodePayloads::interactivelySelectNyxPayloadType()
        return nil if payloadType.nil?
        if payloadType == "nyx-directory" then
            folderpath = NyxDirectories::makeNewDirectory(uuid)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory" # The first nyx-directory is a payload type, and the second is a full payload string
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported payload type: #{payloadType}"
    end

end
