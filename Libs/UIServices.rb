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

        pool, rest = [ns17s.take(3), ns17s.drop(3)]

        poolactive, poolnonactive = pool.partition{|ns17| ns17["rt"] > 0}

        poolactivealpha, poolactivebeta = poolactive.partition{|ns17| ns17["rt"] < 2}

        poolactivebeta = poolactivebeta.map{|ns17|
            ns16 = ns17["ns16"]
            ns16["announce"] = ns16["announce"].red
            ns17["ns16"] = ns16
            ns17
        }

        syntheticIsWinning = (poolactivealpha.size > 0 and synthetic["rt"] < poolactivealpha.map{|ns17| ns17["rt"]}.min)

        if poolactivealpha.size > 0 and !syntheticIsWinning then
            return (poolactivealpha + [synthetic]).sort{|o1, o2| o1["rt"] <=> o2["rt"] } + poolactivebeta.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + poolnonactive + rest
        end

        if poolactivealpha.size > 0 and syntheticIsWinning then
            zeros, nonzeros = ns17s.partition{|ns17| ns17["rt"] == 0}
            return zeros.first(3) + [synthetic] + nonzeros.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + zeros.drop(3)
        end

        if poolactivealpha.size == 0 then
            zeros, nonzeros = ns17s.partition{|ns17| ns17["rt"] == 0}
            return zeros.first(3) + [synthetic] + nonzeros.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + zeros.drop(3)
        end

        raise "23479e0d-3d4e-4ca3-a44e-1c0c567ba84c"
    end

    # UIServices::todoNS16s()
    def self.todoNS16s()
        makeSyntheticNs17 = lambda {|syntheticRT|
            ns16 = {
                "uuid"     => SecureRandom.hex,
                "announce" => "(#{"%5.3f" % syntheticRT}) #{"(/◕ヮ◕)/".green} Synthetic 🚀 🌝",
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
        synthetic = makeSyntheticNs17.call(syntheticRT)
        UIServices::orderNS17s(Quarks::ns17s(), synthetic).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour))
        isWorkTime = (isWorkTime and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        [
            isWorkTime ? [] : UIServices::waveLikeNS16s(),
            isWorkTime ? WorkInterface::ns16s() : [],
            isWorkTime ? UIServices::waveLikeNS16s() : [] ,
            UIServices::todoNS16s()
        ].flatten
    end
end


