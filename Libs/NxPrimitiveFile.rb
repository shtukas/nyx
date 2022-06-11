
# encoding: UTF-8

class NxPrimitiveFile

    # NxPrimitiveFile::issue(filepath, description = nil)
    def self.issue(filepath, description = nil)
        raise "(error: 9bbd60c5-4e4a-4fb6-ae81-2f4c44d0ba10)" if !File.exists?(filepath)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(filepath) # [dottedExtension, nhash, parts]
        raise "(error: 6b608273-a555-420d-abaf-29983d132571)" if data.nil?
        dottedExtension, nhash, parts = data
        item = {
            "uuid"            => SecureRandom.uuid,
            "mikuType"        => "NxPrimitiveFile",
            "unixtime"        => unixtime,
            "datetime"        => datetime,
            "description"     => description,
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
        Librarian::commit(item)
        item
    end

    # NxPrimitiveFile::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            description = nil
        end
        NxPrimitiveFile::issue(location, description)
    end

    # NxPrimitiveFile::toString(item)
    def self.toString(item)
        "(file) #{item["description"]}".strip
    end
end
