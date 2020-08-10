# encoding: UTF-8

class DirectManagement

    # DirectManagement::getLocations()
    def self.getLocations()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/DirectManagement")
    end

    # DirectManagement::locationToString(location)
    def self.locationToString(location)
        if File.file?(location) then
            return "[file  ] #{File.basename(location)}"
        else
            return "[folder] #{File.basename(location)}"
        end
    end

    # DirectManagement::accessLocation(location)
    def self.accessLocation(location)
        raise "[error: edb27d98]" if !File.exists?(location)
        if File.file?(location) then
            system("open '#{location}'") # open the text file
        else
            system("open '#{location}'") # open the folder
        end
    end

    # DirectManagement::identifyALocationByDescriptionOrNull(description)
    def self.identifyALocationByDescriptionOrNull(description)
        # In this first implementation we just expect it to be equal to a section of the base name
        DirectManagement::getLocations()
            .select{|location| File.basename(location).include?(description) }
            .first
    end

end
