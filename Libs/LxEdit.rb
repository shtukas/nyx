
class LxEdit

    # LxEdit::edit(item) # item
    def self.edit(item)

        if item["mikuType"] == "" then
            text = CommonUtils::editTextSynchronously(item["text"])
            DxF1::setAttribute2(item["uuid"], "text", text)
            return DxF1::getProtoItemOrNull(item["uuid"])
        end

        item
    end
end