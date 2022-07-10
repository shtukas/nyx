class AionTransforms

    # AionTransforms::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # AionTransforms::extractDottedExtensionOrNull(str)
    def self.extractDottedExtensionOrNull(str)

        extension = File.extname(str)

        return nil if extension == ""

        if XCache::getFlag("extension-is-valid-be8815b71e65:#{extension}") then
            return extension
        end

        if XCache::getFlag("extension-is-NOT-valid-0f93768b37d9:#{extension}") then
            return extension
        end

        # By this point, we do not know if the extension is valid or not

        puts "str      : #{str}"
        puts "extension: #{extension}"
        if LucilleCore::askQuestionAnswerAsBoolean("extension valid ? ") then
            XCache::setFlag("extension-is-valid-be8815b71e65:#{extension}", true)
            return extension
        else
            XCache::setFlag("extension-is-NOT-valid-0f93768b37d9:#{extension}", true)
            return nil
        end
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

        desiredName
    end

    # AionTransforms::rewriteThisAionRootWithNewTopName(operator, rootnhash, desiredName)
    def self.rewriteThisAionRootWithNewTopName(operator, rootnhash, desiredName)
        aionObject = AionCore::getAionObjectByHash(operator, rootnhash)
        aionObject["name"] = AionTransforms::decideLocationName(aionObject["name"], desiredName) 
        blob = JSON.generate(aionObject)
        operator.putBlob(blob)
    end
end
