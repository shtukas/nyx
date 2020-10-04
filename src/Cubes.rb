
# encoding: UTF-8

=begin
{
    "uuid"          : String
    "nyxNxSet"      : "06071daa-ec51-4c19-a4b9-62f39bb2ce4f"
    "unixtime"      : Float # Unixtime with decimals
    "description"   : String
    "location"      : String # Folder path to the listing
}
=end

class Cubes

    # Cubes::issueCube(description, location)
    def self.issueCube(description, location)
        cube = {
            "uuid"          => SecureRandom.hex,
            "nyxNxSet"      => "06071daa-ec51-4c19-a4b9-62f39bb2ce4f",
            "unixtime"      => Time.new.to_f, # Unixtime with decimals
            "description"   => description,
            "location"      => location # Folder path to the listing
        }
        NyxObjects2::put(cube)
        cube
    end

    # Cubes::toString(cube)
    def self.toString(cube)
        "[cube] #{cube["description"]}"
    end

    # Cubes::cubes()
    def self.cubes()
        NyxObjects2::getSet("06071daa-ec51-4c19-a4b9-62f39bb2ce4f")
    end

    # Cubes::cubeLanding(cube)
    def self.cubeLanding(cube)
        system("clear")
        puts "cube landing:"
        puts Cubes::toString(cube)
        LucilleCore::pressEnterToContinue()
    end

    # Cubes::cubesDive()
    def self.cubesDive()
        loop {
            system("clear")

            mx = LCoreMenuItemsNX1.new()

            Cubes::cubes().each{|cube|
                mx.item(Cubes::toString(cube), lambda {
                    Cubes::cubeLanding(cube)
                })
            }

            status = mx.promptAndRunSandbox()
            break if !status
        }


    end
end
