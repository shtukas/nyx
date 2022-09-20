
class PolyPrograms

    # PolyPrograms::itemLanding(item)
    def self.itemLanding(item)
        if item["mikuType"] == "fitness1" then
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::landing(item)
            return
        end

        if item["mikuType"] == "TxTimeCommitment" then
            TxTimeCommitments::landing(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::landing(item)
            return
        end

        if item["mikuType"] == "TxDated" then
            TxDateds::landing(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxTasks::landing(item)
            return
        end

        if item["mikuType"] == "NyxNode" then
            NyxNodes::landing(item)
            return
        end

        raise "(error: D9DD0C7C-ECC4-46D0-A1ED-CD73591CC87B): item: #{item}"
    end
end
