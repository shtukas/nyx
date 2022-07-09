class AionTransforms

    # AionTransforms::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # AionTransforms::extractDottedExtensionOrNull(str)
    def self.extractDottedExtensionOrNull(str)

        # We are making the following small adjustement to prevent:
        # str       = 51|(task) Screenshot 2021-09-28 at 15.13.39.png (aion-point)|fa5ab5d4-e2d3-44c2-9fe3-82ff19761f52|eaa0487d9f91e11256dfee4faaa2a282
        # extension = .png (aion-point)|fa5ab5d4-e2d3-44c2-9fe3-82ff19761f52|eaa0487d9f91e11256dfee4faaa2a282
        str = str[-10, 10]

        extension = File.extname(str)

        # Handling special cirumstances.
        return nil if extension == ".)"

        return nil if extension == ""

        extension
    end

    # AionTransforms::decideLocationName(aionRootName, desiredName)
    def self.decideLocationName(aionRootName, desiredName)
        aionRootNameExtension = AionTransforms::extractDottedExtensionOrNull(aionRootName)
        desiredNameExtension = AionTransforms::extractDottedExtensionOrNull(desiredName)
        if aionRootNameExtension and desiredNameExtension and aionRootNameExtension != desiredNameExtension then
            puts "AionTransforms::decideLocationName(aionRootName, desiredName)"
            puts "aionRootName: #{aionRootName}, aionRootNameExtension: #{aionRootNameExtension}"
            puts "desiredName:  #{desiredName}, desiredNameExtension: #{desiredNameExtension}"
            raise "(error: 4da4407a-08c9-4bc5-bab9-b99224bed1de)"
        end
        if aionRootNameExtension and desiredNameExtension and aionRootNameExtension == desiredNameExtension then
            return desiredName
        end
        if aionRootNameExtension and desiredNameExtension.nil? then
            return "#{desiredName}#{aionRootNameExtension}"
        end
        puts "AionTransforms::decideLocationName(aionRootName, desiredName)"
        puts "aionRootName: #{aionRootName}, aionRootNameExtension: #{aionRootNameExtension}"
        puts "desiredName:  #{desiredName}, desiredNameExtension: #{desiredNameExtension}"
        raise "(error: 5857269b-ac3d-40b2-8a89-3023043e8355)"
    end

    # AionTransforms::rewriteThisAionRootWithNewTopName(operator, rootnhash, desiredName)
    def self.rewriteThisAionRootWithNewTopName(operator, rootnhash, desiredName)
        aionObject = AionCore::getAionObjectByHash(operator, rootnhash)
        aionObject["name"] = AionTransforms::decideLocationName(aionObject["name"], desiredName) 
        blob = JSON.generate(aionObject)
        operator.putBlob(blob)
    end
end
