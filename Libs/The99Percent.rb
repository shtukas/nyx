# encoding: UTF-8

class The99Percent

    # reference = {
    #     "count"    =>
    #     "datetime" =>
    # }

    # The99Percent::issueNewReferenceOrNull()
    def self.issueNewReferenceOrNull()
        system("clear")
        count = The99Percent::getCurrentCount()
        reference = {
            "count"    => count,
            "datetime" => Time.new.utc.iso8601
        }
        puts JSON.pretty_generate(reference).green
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("Issue this new reference ? ")
        XCache::set("002c358b-e6ee-41bd-9bee-105396a6349a", JSON.generate(reference))
        reference
    end

    # The99Percent::getReferenceOrNull()
    def self.getReferenceOrNull()
        reference = XCache::getOrNull("002c358b-e6ee-41bd-9bee-105396a6349a")
        if reference then
            JSON.parse(reference)
        else
            The99Percent::issueNewReferenceOrNull()
        end
    end

    # The99Percent::getCurrentCount()
    def self.getCurrentCount()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo").size
    end

    # The99Percent::ratioOrNull()
    def self.ratioOrNull()
        reference = The99Percent::getReferenceOrNull()
        return nil if reference.nil?
        current   = The99Percent::getCurrentCount()
        current.to_f/reference["count"]
    end

    # The99Percent::recomputeFromStratch()
    def self.recomputeFromStratch()
        reference = The99Percent::getReferenceOrNull()
        return nil if reference.nil?
        current = The99Percent::getCurrentCount()
        ratio   = current.to_f/reference["count"]
        if ratio < 0.99 then
            The99Percent::issueNewReferenceOrNull()
            return
        end
        line = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
        XCache::set("8c07eb2c-d7d0-489a-a6d1-7e66ecac5a69", line)
    end

    # The99Percent::displayLineFromCacheOrNull()
    def self.displayLineFromCacheOrNull()
        XCache::getOrNull("8c07eb2c-d7d0-489a-a6d1-7e66ecac5a69")
    end
end
