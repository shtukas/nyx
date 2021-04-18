# encoding: UTF-8

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {

            ms = LCoreMenuItemsNX1.new()

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })

            ms.item("new quark", lambda { Quarks::interactivelyIssueNewMarbleQuarkOrNull(Quarks::computeLowL22()) })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::orderNS17s(ns17s, synthetic)
    def self.orderNS17s(ns17s, synthetic)
        depth = 3
        activeWithinDepth, nonActiveWithinDepth = ns17s.first(depth).partition{|ns17| ns17["rt"] > 0}

        if activeWithinDepth.size > 0 and synthetic["rt"] < activeWithinDepth.map{|ns17| ns17["rt"]}.min then
            # There are some active with depth and we are below them
            # Need to do some zero
            zeros, nonzeros = ns17s.partition{|ns17| ns17["rt"] == 0}
            zeros.first(depth) + [synthetic] + nonzeros.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + zeros.drop(depth)
        else
            (activeWithinDepth + (activeWithinDepth.size > 0 ? [synthetic] : [])).sort{|o1, o2| o1["rt"] <=> o2["rt"] } + nonActiveWithinDepth + ns17s.drop(depth)
        end
    end

    # UIServices::todoNS16s()
    def self.todoNS16s()
        makeSyntheticNs17 = lambda {|syntheticRT, trackingNumbers|
            ns16 = {
                "uuid"     => SecureRandom.hex,
                "announce" => "(#{"%5.3f" % syntheticRT}) #{"(/◕ヮ◕)/".green} Synthetic 🚀 🌝 (#{trackingNumbers["current"]}, #{trackingNumbers["performance"]})",
                "start"    => lambda { },
                "done"     => lambda { }
            }
            {
                "ns16"      => ns16,
                "rt"        => syntheticRT,
                "synthetic" => true
            }
        }
        syntheticRT = Synthetic::getRecoveryTimeInHours()
        trackingNumbers = Synthetic::targettingNumbers(Time.now.utc.iso8601)
        synthetic = makeSyntheticNs17.call(syntheticRT, trackingNumbers)
        UIServices::orderNS17s(Quarks::ns17s(), synthetic).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour))
        isWorkTime = (isWorkTime and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        [
            isWorkTime ? [] : UIServices::waveLikeNS16s(),
            isWorkTime ? WorkTxt::ns16s() : [],
            isWorkTime ? UIServices::waveLikeNS16s() : [] ,
            UIServices::todoNS16s()
        ].flatten
    end
end


