
# encoding: UTF-8

class Payload1

    # Payload1::types()
    def self.types()
        ["null", "Nx113", "NxQuantumDrop", "NxGridFiber"]
    end

    # Payload1::interactivelySelectOneTypeOrNull()
    def self.interactivelySelectOneTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Payload1 type (none to abort):", Payload1::types())
    end

    # Payload1::makeNewUsingLocation(location)
    def self.makeNewUsingLocation(location)
        {
            "mikuType" => "NyxNodePayload1",
            "type"     => "Nx113",
            "nx113"    => Nx113Make::aionpoint(location)
        }
    end

    # Payload1::makeNewUsingFile(filepath)
    def self.makeNewUsingFile(filepath)
        {
            "mikuType" => "NyxNodePayload1",
            "type"     => "Nx113",
            "nx113"    => Nx113Make::file(filepath)
        }
    end

    # Payload1::makeNewText()
    def self.makeNewText()
        text = CommonUtils::editTextSynchronously("")
        {
            "mikuType" => "NyxNodePayload1",
            "type"     => "Nx113",
            "nx113"    => Nx113Make::text(text)
        }
    end

    # Payload1::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = Payload1::interactivelySelectOneTypeOrNull()
        return nil if type.nil?
        if type == "null" then
            return {
                "mikuType" => "NyxNodePayload1",
                "type"     => "null"
            }
        end
        if type == "Nx113" then
            nx113 = Nx113Make::interactivelyMakeNx113OrNull()
            if nx113.nil? then
                return Payload1::interactivelyMakeNewOrNull()
            end
            return {
                "mikuType" => "NyxNodePayload1",
                "type"     => "Nx113",
                "nx113"    => nx113
            }
        end
        if type == "NxQuantumDrop" then
            drop = QuantumDrops::issueNewDrop(SecureRandom.uuid, [])
            return {
                "mikuType" => "NyxNodePayload1",
                "type"     => "NxQuantumDrop",
                "drop"     => drop
            }
        end
        if type == "NxGridFiber" then
            raise "not ready yet"
        end
        raise "(error: eaac753f-4b91-4190-93f8-25140e6b18e0) unsupported type: #{type}"
    end

    # Payload1::interactivelyMake()
    def self.interactivelyMake()
        loop {
            payload_1 = Payload1::interactivelyMakeNewOrNull()
            return payload_1 if payload_1
        }
    end

    # Payload1::toString(payload_1)
    def self.toString(payload_1)
        payload_1["type"]
    end

    # Payload1::access(payload_1)
    def self.access(payload_1)
        type = payload_1["type"]
        if type == "null" then
            return
        end
        if type == "Nx113" then
            Nx113Access::access(payload_1["nx113"])
            return
        end
        if type == "NxQuantumDrop" then
            drop = payload_1["drop"] # NxQuantumDrop
            QuantumDrops::accessNxQuantumDrop(drop)
            return
        end
        if type == "NxGridFiber" then
            raise "not ready yet"
        end

        raise "(error: 2dc30268-c7b8-489b-a07c-77ee3f276a2a) unsupported type #{type}"
    end

    # Payload1::edit(payload_1) # Payload1 or null if no change
    def self.edit(payload_1)
        type = payload_1["type"]
        if type == "null" then
            return nil
        end
        if type == "Nx113" then
            nx113v2 = Nx113Edit::editNx113(payload_1["nx113"])
            return nil if nx113v2.nil?
            return {
                "mikuType" => "NyxNodePayload1",
                "type"     => "Nx113",
                "nx113"    => nx113v2
            }
        end
        if type == "NxQuantumDrop" then
            drop = payload_1["drop"] # NxQuantumDrop
            drop = QuantumDrops::editNxQuantumDrop(drop) # NxQuantumDrop
            return {
                "mikuType" => "NyxNodePayload1",
                "type"     => "NxQuantumDrop",
                "drop"     => drop
            }
        end
        if type == "NxGridFiber" then
            raise "not ready yet"
        end

        raise "(error: 94a24ca8-2b47-41cb-aa1c-e01dd4580ffe) unsupported type #{type}"
    end
end
