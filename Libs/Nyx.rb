
# encoding: UTF-8

class Nyx

    # Nyx::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/NxData/03-Nyx"
    end

    # Nyx::main()
    def self.main()
        loop {
            options = ["search", "make new node"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                SearchNyx::run()
            end
            if option == "make new node" then
                NxNodes::interactivelyIssueNewOrNull()
            end
        }
    end
end
