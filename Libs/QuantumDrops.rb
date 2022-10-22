
class QuantumDrops

    # QuantumDrops::issueNewDrop(uuid, quantumStates)
    def self.issueNewDrop(uuid, quantumStates)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxQuantumDrop",
            "quantumStates" => quantumStates
        }
        # We can file system check the drop here
        filename = "QuantumDrop-#{uuid}"
        filepath = "#{Config::userHomeDirectory()}/Desktop/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        puts "I have put the drop on the Desktop (#{filename})"
        LucilleCore::pressEnterToContinue()
        item
    end

end
