
# encoding: UTF-8

class Nyx

    # Nyx::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/Nyx"
    end

    # Nyx::main()
    def self.main()
        loop {
            options = ["search", "new orbital", "list orbitals", "fs scan"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                NightSky::search_action()
            end
            if option == "new orbital" then
                orbital = NightSky::interactivelyIssueNewNxOrbitalNull()
                next if orbital.nil?
                NightSky::landing(orbital)
            end
            if option == "list orbitals" then
                loop {
                    orbitals = NightSky::orbitals().sort{|n1, n2| n1.unixtime() <=> n2.unixtime() }
                    orbital = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", orbitals, lambda{|orbital| orbital.description() })
                    break if orbital.nil?
                    NightSky::landing(orbital)
                }
            end
            if option == "fs scan" then
                NightSky::fs_scan()
            end
        }
    end
end

