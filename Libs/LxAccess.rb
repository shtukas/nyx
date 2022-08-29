
class LxAccess

    # LxAccess::access(item)
    def self.access(item)

        
        if item["mikuType"] == "DxText" then
            CommonUtils::accessText(item["text"])
        end

        if item["mikuType"] == "NxTask" then
            Nx112::carrierAccess(item)
        end

        if item["mikuType"] == "Wave" then
            Nx112::carrierAccess(item)
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mnikuType: #{item["mikuType"]}"
    end
end