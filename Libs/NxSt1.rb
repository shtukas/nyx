
# encoding: UTF-8

class NxSt1

    # NxSt1::types()
    def self.types()
        ["null", "Nx113", "NxQuantumDrop", "Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
    end

    # NxSt1::interactivelySelectOneTypeOrNull()
    def self.interactivelySelectOneTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("NxSt1 type (none to abort):", NxSt1::types())
    end

    # NxSt1::makeNewUsingLocation(location)
    def self.makeNewUsingLocation(location)
        {
            "type"  => "Nx113",
            "nx113" => Nx113Make::aionpoint(location)
        }
    end

    # NxSt1::makeNewUsingFile(filepath)
    def self.makeNewUsingFile(filepath)
        {
            "type"  => "Nx113",
            "nx113" => Nx113Make::file(filepath)
        }
    end

    # NxSt1::makeNewText()
    def self.makeNewText()
        text = CommonUtils::editTextSynchronously("")
        {
            "type"  => "Nx113",
            "nx113" => Nx113Make::text(text)
        }
    end

    # NxSt1::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = NxSt1::interactivelySelectOneTypeOrNull()
        return nil if type.nil?
        if type == "null" then
            return {
                "type" => "null"
            }
        end
        if type == "Nx113" then
            nx113 = Nx113Make::interactivelyMakeNx113OrNull()
            if nx113.nil? then
                return NxSt1::interactivelyMakeNewOrNull()
            end
            return {
                "type"  => "Nx113",
                "nx113" => nx113
            }
        end
        if type == "NxQuantumDrop" then
            puts "We are not yet offering Quantum Drops"
            LucilleCore::pressEnterToContinue()
            return NxSt1::interactivelyMakeNewOrNull()
            drop = nil
            return {
                "type" => "NxQuantumDrop",
                "drop" => drop
            }
        end
        if type == "Entity" then
            return {
                "type" => "Entity"
            }
        end
        if type == "Concept" then
            return {
                "type" => "Concept"
            }
        end
        if type == "Event" then
            nx113 = Nx113Make::interactivelyMakeNx113OrNull()
            if nx113.nil? then
                return NxSt1::interactivelyMakeNewOrNull()
            end
            return {
                "type"  => "Event",
                "nx113" => nx113
            }
        end
        if type == "Person" then
            return {
                "type" => "Person"
            }
        end
        if type == "Collection" then
            return {
                "type" => "Collection"
            }
        end
        if type == "Timeline" then
            return {
                "type" => "Timeline"
            }
        end
        raise "(error: eaac753f-4b91-4190-93f8-25140e6b18e0) unsupported type: #{type}"
    end

    # NxSt1::interactivelyMake()
    def self.interactivelyMake()
        loop {
            nxst1 = NxSt1::interactivelyMakeNewOrNull()
            return nxst1 if nxst1
        }
    end

    # NxSt1::toString(nxst1)
    def self.toString(nxst1)
        nxst1.to_s
    end

    # NxSt1::access(nxst1)
    def self.access(nxst1)
        type = nxst1["type"]
        if type == "null" then
            return
        end
        if type == "Nx113" then
            Nx113Access::access(nxst1["nx113"])
            return
        end
        if type == "NxQuantumDrop" then
            puts "We are not yet offering Quantum Drops"
            LucilleCore::pressEnterToContinue()
            return
        end
        if type == "Entity" then
            return
        end
        if type == "Concept" then
            return
        end
        if type == "Event" then
            Nx113Access::access(nxst1["nx113"])
            return
        end
        if type == "Person" then
            return
        end
        if type == "Collection" then
            return
        end
        if type == "Timeline" then
            return
        end

        raise "(error: 2dc30268-c7b8-489b-a07c-77ee3f276a2a) unsupported type #{type}"
    end

    # NxSt1::edit(nxst1) # NxSt1 or null if no change
    def self.edit(nxst1)
        type = nxst1["type"]
        if type == "null" then
            return nil
        end
        if type == "Nx113" then
            nx113v2 = Nx113Edit::editFunction(nxst1["nx113"])
            return nil if nx113v2.nil?
            return {
                "type"  => "Nx113",
                "nx113" => nx113v2
            }
        end
        if type == "NxQuantumDrop" then
            puts "We are not yet offering Quantum Drops"
            LucilleCore::pressEnterToContinue()
            return
        end
        if type == "Entity" then
            return nil
        end
        if type == "Concept" then
            return nil
        end
        if type == "Event" then
            nx113v2 = Nx113Edit::editFunction(nxst1["nx113"])
            return nil if nx113v2.nil?
            return {
                "type"  => "Event",
                "nx113" => nx113v2
            }
        end
        if type == "Person" then
            return nil
        end
        if type == "Collection" then
            return nil
        end
        if type == "Timeline" then
            return nil
        end

        raise "(error: 94a24ca8-2b47-41cb-aa1c-e01dd4580ffe) unsupported type #{type}"
    end
end
