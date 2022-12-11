class EnergyGrid

    # EnergyGrid::energyGridPath()
    def self.energyGridPath()
        "/Volumes/EnergyGrid1"
    end

    # EnergyGrid::acquireEnergyGridOrExit()
    def self.acquireEnergyGridOrExit()
        return if File.exists?(EnergyGrid::energyGridPath())
        puts "We need Energy Grid"
        LucilleCore::pressEnterToContinue()
        return if File.exists?(EnergyGrid::energyGridPath())
        exit
    end
end
