
class LxEdit

    # LxEdit::edit(item) # item
    def self.edit(item)

        if item["mikuType"] == "DxText" then
            text = CommonUtils::editTextSynchronously(item["text"])
            DxF1::setAttribute2(item["uuid"], "text", text)
            return DxF1::getProtoItemOrNull(item["uuid"])
        end

        if item["mikuType"] == "DxAionPoint" then
            operator = DxF1Elizabeth.new(item["uuid"], true, true)
            rootnhash = item["rootnhash"]
            parentLocation = "#{ENV['HOME']}/Desktop/DxPure-Edit-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(parentLocation)
            AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
            puts "Item exported at #{parentLocation}. Continue to upload update"
            LucilleCore::pressEnterToContinue()

            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return if location.nil?

            uuid = item["uuid"]
            operator = DxF1Elizabeth.new(uuid, true, true)
            rootnhash = AionCore::commitLocationReturnHash(operator, location)
            DxF1::setAttribute2(uuid, "rootnhash", rootnhash)
            FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)

            return DxF1::getProtoItemOrNull(item["uuid"])
        end

        item
    end
end