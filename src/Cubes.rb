
# encoding: UTF-8

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

    # Cubes::landing(cube)
    def self.landing(cube)
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            puts Cubes::toString(cube).green
            puts "uuid: #{cube["uuid"]}"

            puts ""

            source = Arrows::getSourcesForTarget(cube)
            source.each{|source|
                ms.item(
                    "source: #{NyxObjectInterface::toString(source)}",
                    lambda { NyxObjectInterface::landing(source) }
                )
            }

            puts ""

            Arrows::getTargetsForSource(cube).each{|target|
                ms.item(
                    "target: #{NyxObjectInterface::toString(target)}",
                    lambda { NyxObjectInterface::landing(target) }
                )
            }

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # Cubes::cubesListing()
    def self.cubesListing()
        loop {
            system("clear")

            mx = LCoreMenuItemsNX1.new()

            Cubes::cubes().each{|cube|
                mx.item(Cubes::toString(cube), lambda {
                    Cubes::landing(cube)
                })
            }

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Cubes::selectCubeOrNull()
    def self.selectCubeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", Cubes::cubes(), lambda{ |cube| Cubes::toString(cube) })
    end

    # Cubes::fsck()
    def self.fsck()
        Cubes::cubes().each{|cube|
            if !File.exists?(cube["location"]) then
                puts "Failure to find cube location"
                puts JSON.pretty_generate(cube)
                raise "0ef259eb-ea43-4084-b442-70d795831ac0"
            end
        }
    end
end
