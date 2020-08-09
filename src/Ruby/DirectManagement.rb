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

end
