
# encoding: UTF-8

class Tags

    # Tags::make(payload)
    def self.make(payload)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "25bb489f-a25b-46af-938a-96cc42e2694c",
            "unixtime" => Time.new.to_f,
            "payload"  => payload
        }
    end

    # Tags::issue(payload)
    def self.issue(payload)
        tag = Tags::make(payload)
        NyxObjects2::put(tag)
        tag
    end

    # Tags::toString(tag)
    def self.toString(tag)
        "[tag] #{tag["payload"]}"
    end

    # Tags::tags()
    def self.tags()
        NyxObjects2::getSet("25bb489f-a25b-46af-938a-96cc42e2694c")
    end

    # Tags::landing(tag)
    def self.landing(tag)
        loop {
            system("clear")

            puts Tags::toString(tag).green

            puts ""

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(tag)
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

end
