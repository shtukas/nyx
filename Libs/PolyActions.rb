
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
        if item["mikuType"] == "NxDot41" then
            x = NxDot41s::program(item)
            if x then
                return x # was selected during a dive
            end
        end
    end
end
