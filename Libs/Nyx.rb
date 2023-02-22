
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
                NyxSearch::run()
            end
            if option == "new orbital" then
                orbital = NightSky::interactivelyIssueNewNxOrbitalNull()
                next if orbital.nil?
                NightSky::landing(orbital)
            end
            if option == "list orbitals" then
                loop {
                    orbitals = NightSky::orbitals().sort{|n1, n2| n1.unixtime() <=> n2.unixtime() }
                    orbital = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", orbitals, lambda{|orbital| orbital.to_string() })
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

class NyxSearch

    # NyxSearch::nx20s() # Array[Nx20]
    def self.nx20s()
        NightSky::orbitals()
            .map{|orbital|
                {
                    "announce" => orbital.to_string(),
                    "unixtime" => orbital.unixtime(),
                    "orbital"  => orbital
                }
            }
    end

    # NyxSearch::run()
    def self.run()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = NyxSearch::nx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = NyxSearch::nx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                NightSky::landing(nx20["orbital"])
            }
        }
        nil
    end
end

