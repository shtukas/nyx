
class PolyActions

    # PolyActions::program(item)
    def self.program(item)
        if item["mikuType"] == "NxNote" then
            NxNote::program(item)
        end
        if item["mikuType"] == "NxCoreDataRef" then
            reference = item
            CoreDataRefsNxCDRs::program(node["uuid"], reference)
        end
        if item["mikuType"] == "Nx101" then
            x = Nx101::program(item)
            if x then
                return x # was selected during a dive
            end
        end
        if item["mikuType"] == "NxAionPoints0849" then
            x = NxAionPoints0849::program(item)
            if x then
                return x # was selected during a dive
            end
        end
        if item["mikuType"] == "NxUrl1005" then
            x = NxUrl1005::program(item)
            if x then
                return x # was selected during a dive
            end
        end
    end

    # PolyActions::destroy(uuid, message)
    def self.destroy(uuid, message)
        puts "> request to destroy nyx node: #{message}"
        code1 = SecureRandom.hex(2)
        code2 = LucilleCore::askQuestionAnswerAsString("Enter destruction code (#{code1}): ")
        if code1 == code2 then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction: ") then
                Cubes::destroy(uuid)
                return
            end
        end
    end
end
