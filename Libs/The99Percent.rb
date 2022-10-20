# encoding: UTF-8

class The99Percent

    # reference = {
    #     "count"    =>
    #     "datetime" =>
    # }

    # The99Percent::issueNewReferenceOrNull()
    def self.issueNewReferenceOrNull()
        count = The99Percent::getCurrentCount()
        reference = {
            "count"    => count,
            "datetime" => Time.new.utc.iso8601
        }
        puts JSON.pretty_generate(reference).green
        return if !LucilleCore::askQuestionAnswerAsBoolean("Issue this new reference ? ")
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
        NxTodos::items().size
    end

    # The99Percent::ratio()
    def self.ratio()
        reference = The99Percent::getReferenceOrNull()
        current   = The99Percent::getCurrentCount()
        current.to_f/reference["count"]
    end

    # The99Percent::displayLineFromScratchWithCacheUpdate()
    def self.displayLineFromScratchWithCacheUpdate()
        reference = The99Percent::getReferenceOrNull()
        current   = The99Percent::getCurrentCount()
        ratio     = current.to_f/reference["count"]
        line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
        if ratio < 0.99 then
            The99Percent::issueNewReferenceOrNull()
            return "Just issued a new reference"
        end
        XCache::set("8c07eb2c-d7d0-489a-a6d1-7e66ecac5a69", line)
        line
    end

    # The99Percent::displayLineFromCache()
    def self.displayLineFromCache()
        XCache::getOrNull("8c07eb2c-d7d0-489a-a6d1-7e66ecac5a69")
    end
end
