
# encoding: UTF-8

class Islands

    # Islands::make(name_)
    def self.make(name_)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "287041db-39ac-464c-b557-2f172e721111",
            "unixtime" => Time.new.to_f,
            "name"     => name_
        }
    end

    # Islands::issue(name_)
    def self.issue(name_)
        island = Islands::make(name_)
        NyxObjects2::put(island)
        island
    end

    # Islands::toString(island)
    def self.toString(island)
        "[island] #{island["name"]}"
    end

    # Islands::islands()
    def self.islands()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Islands::landing(island)
    def self.landing(island)
        loop {
            system("clear")

            puts Islands::toString(island).green

            puts ""

            mx = LCoreMenuItemsNX1.new()

            puts "Connections:"
            Links::getLinkedObjectsForCenter(island).each{|i|
                puts "    - #{Islands::toString(i)}"
                mx.item(
                    Islands::toString(i),
                    lambda { Islands::landing(i) }
                )
            }

            puts ""

            puts "Contents:"

            targets = Arrows::getTargetsForSource(island)
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            targets
                .each{|object|
                    mx.item(
                        NyxObjectInterface::toString(object),
                        lambda { NyxObjectInterface::landing(object) }
                    )
                }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Islands::islandsDive()
    def self.islandsDive()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Islands::islands().each{|island|
                mx.item(
                    Islands::toString(island),
                    lambda { Islands::landing(island) }
                )
            }
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
