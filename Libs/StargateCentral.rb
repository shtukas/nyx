class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/EnergyGrid1/Data/Pascal/Galaxy/Stargate-Central"
    end

    # StargateCentral::isVisible()
    def self.isVisible()
        File.exists?(StargateCentral::pathToCentral())
    end

    # StargateCentral::ensureCentral()
    def self.ensureCentral()
        return if File.exists?(StargateCentral::pathToCentral())
        puts "I need the EnergyGrid1 drive, please plug".green
        LucilleCore::pressEnterToContinue()
        return if File.exists?(StargateCentral::pathToCentral())
        puts "Could not find the EnergyGrid1 drive. Exiting."
        exit 1
    end

    # StargateCentral::attemptCentral()
    def self.attemptCentral() # Boolean # Indicates whether we got there or not
        return true if File.exists?(StargateCentral::pathToCentral())
        puts "I need the EnergyGrid1 drive, please plug".green
        LucilleCore::pressEnterToContinue()
        File.exists?(StargateCentral::pathToCentral())
    end
end
