
# encoding: UTF-8

class Tags

    # Tags::make(payload)
    def self.make(payload)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "287041db-39ac-464c-b557-2f172e721111",
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

    # Tags::issueSetInteractivelyOrNull()
    def self.issueSetInteractivelyOrNull()
        payload = LucilleCore::askQuestionAnswerAsString("tag payload: ")
        return nil if payload == ""
        Tags::issue(payload)
    end

    # Tags::toString(tag)
    def self.toString(tag)
        "[tag] #{tag["payload"]}"
    end

    # Tags::tags()
    def self.tags()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Tags::landing(tag)
    def self.landing(tag)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(tag["uuid"]).nil?

            puts Tags::toString(tag).green
            puts "uuid: #{tag["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(tag)
            targets = targets.select{|target| !GenericNyxObject::isTag(target) }
            targets = GenericNyxObject::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
            targets
                .each{|object|
                    mx.item(
                        GenericNyxObject::toString(object),
                        lambda { GenericNyxObject::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                payload = Miscellaneous::editTextSynchronously(tag["payload"]).strip
                return if payload == ""
                tag["payload"] = payload
                NyxObjects2::put(tag)
                Tags::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = NGX15::issueNewNGX15InteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(tag, datapoint)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(tag)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy tag".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy tag: '#{Tags::toString(tag)}': ") then
                    NyxObjects2::destroy(tag)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Tags::tagsListing()
    def self.tagsListing()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Tags::tags().each{|tag|
                mx.item(
                    Tags::toString(tag),
                    lambda { Tags::landing(tag) }
                )
            }
            puts ""
            mx.item("Make new tag".yellow, lambda { 
                i = Tags::issueSetInteractivelyOrNull()
                return if i.nil?
                Tags::landing(i)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # ----------------------------------

    # Tags::payloadIsUsed(payload)
    def self.payloadIsUsed(payload)
        Tags::tags().any?{|tag| tag["payload"].downcase == payload.downcase }
    end

    # Tags::selectExistingSetOrNull_v1()
    def self.selectExistingSetOrNull_v1()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", Tags::tags(), lambda { |tag| Tags::toString(tag) })
    end

    # Tags::pecoStyleSelectTagNameOrNull()
    def self.pecoStyleSelectTagNameOrNull()
        payloads = Tags::tags().map{|tag| tag["payload"] }.sort

        # ---------------------------------------
        fragmentForPreselection = LucilleCore::askQuestionAnswerAsString("fragment for preselection: ")
        payloads = payloads.select{|payload| payload.downcase.include?(fragmentForPreselection.downcase) }.first(1000)
        # ---------------------------------------

        Miscellaneous::pecoStyleSelectionOrNull(payloads)
    end

    # Tags::selectTagByNameOrNull(payload)
    def self.selectTagByNameOrNull(payload)
        Tags::tags()
            .select{|tag| tag["payload"].downcase == payload.downcase }
            .first
    end

    # Tags::selectExistingTagOrNull_v2()
    def self.selectExistingTagOrNull_v2()
        n = Tags::pecoStyleSelectTagNameOrNull()
        return nil if n.nil?
        Tags::selectTagByNameOrNull(n)
    end

    # Interface
    # Tags::selectExistingTagOrMakeNewOneOrNull()
    def self.selectExistingTagOrMakeNewOneOrNull()
        tag = Tags::selectExistingTagOrNull_v2()
        return tag if tag
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new tag ? ") then
            loop {
                payload = LucilleCore::askQuestionAnswerAsString("tag payload: ")
                if Tags::selectTagByNameOrNull(payload) then
                    return Tags::selectTagByNameOrNull(payload)
                end
                return Tags::issue(payload)
            }
        end
        nil
    end

    # ----------------------------------

    # Tags::mergeTwoTagsOfSameNameReturnTag(tag1, tag2)
    def self.mergeTwoTagsOfSameNameReturnTag(tag1, tag2)
        raise "4c54ea8b-7cb4-4838-98ed-66857bd22616" if ( tag1["uuid"] == tag2["uuid"] )
        raise "7d4b9f3e-9fe0-4594-a3c4-61d177a3a904" if ( tag1["payload"].downcase != tag2["payload"].downcase )
        tag = Tags::issue(tag1["payload"])

        Arrows::getSourcesForTarget(tag1).each{|source|
            Arrows::issueOrException(source, tag)
        }
        Arrows::getTargetsForSource(tag1).each{|target|
            Arrows::issueOrException(tag, target)
        }

        Arrows::getSourcesForTarget(tag2).each{|source|
            Arrows::issueOrException(source, tag)
        }
        Arrows::getTargetsForSource(tag2).each{|target|
            Arrows::issueOrException(tag, target)
        }

        NyxObjects2::destroy(tag1)
        NyxObjects2::destroy(tag2)

        tag
    end

    # Tags::redundancyPairOrNull()
    def self.redundancyPairOrNull()
        Tags::tags().combination(2).each{|tag1, tag2|
            next if tag1["payload"].downcase != tag2["payload"].downcase 
            return [tag1, tag2]
        }
        nil
    end

    # Interface
    # Tags::removeSetDuplicates()
    def self.removeSetDuplicates()
        while pair = Tags::redundancyPairOrNull() do
            tag1, tag2 = pair
            Tags::mergeTwoTagsOfSameNameReturnTag(tag1, tag2)
        end
    end

    # ----------------------------------

    # Tags::batchRename(oldpayload, newpayload)
    def self.batchRename(oldpayload, newpayload)
        Tags::tags()
            .each{|tag|
                next if (tag["payload"] != oldpayload)
                tag["payload"] = newpayload
                NyxObjects2::put(tag)
            }
    end
end
