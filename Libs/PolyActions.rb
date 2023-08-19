
class PolyActions

    # PolyActions::program(item)
    def self.program(item)
        if item["mikuType"] == "NxNote" then
            NxNotes::program(item)
        end
        if item["mikuType"] == "NxCoreDataRef" then
            reference = item
            CoreDataRefsNxCDRs::program(node["uuid"], reference)
        end
        if item["mikuType"] == "Nx101" then
            x = Nx101s::program(item)
            if x then
                return x # was selected during a dive
            end
        end
        if item["mikuType"] == "NxAvaldi" then
            x = NxAvaldis::program(item)
            if x then
                return x # was selected during a dive
            end
        end
    end

    # PolyActions::destroy(uuid, description)
    def self.destroy(uuid, description)
        puts "> request to destroy nyx node: #{description}"
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
