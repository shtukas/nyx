# encoding: UTF-8

class The99Percent

    # reference = {
    #     "count"    =>
    #     "datetime" =>
    # }

    # The99Percent::getCurrentCount()
    def self.getCurrentCount()
        count = Database2::filepaths()
                    .reduce(0){|sum, filepath|
                        count = nil
                        db = SQLite3::Database.new(filepath)
                        db.busy_timeout = 117
                        db.busy_handler { |count| true }
                        db.results_as_hash = true
                        db.execute("select count(*) as _count_ from objects where mikuType=?", ["NxTodo"]) do |row|
                            count = row["_count_"]
                        end
                        db.close
                        sum + count
                    }
        [count, 1].max # It should not be 0, because we divide by it.
    end

    # The99Percent::issueNewReference()
    def self.issueNewReference()
        count = The99Percent::getCurrentCount()
        reference = {
            "count"    => count,
            "datetime" => Time.new.utc.iso8601
        }
        XCache::set("002c358b-e6ee-41bd-9bee-105396a6349a", JSON.generate(reference))
        reference
    end

    # The99Percent::getReference()
    def self.getReference()
        reference = XCache::getOrNull("002c358b-e6ee-41bd-9bee-105396a6349a")
        if reference then
            return JSON.parse(reference)
        end
        The99Percent::issueNewReference()
    end

    # The99Percent::ratio()
    def self.ratio()
        reference = The99Percent::getReference()
        current   = The99Percent::getCurrentCount()
        ratio = current.to_f/reference["count"]
        if ratio < 0.99 then
            reference = The99Percent::issueNewReference()
            ratio = current.to_f/reference["count"]
        end
        if ratio > 1.01 then
            reference = The99Percent::issueNewReference()
            ratio = current.to_f/reference["count"]
        end
        ratio
    end

    # The99Percent::line()
    def self.line()
        reference = The99Percent::getReference()
        current = The99Percent::getCurrentCount()
        ratio   = The99Percent::ratio()
        "> inventory: #{current}, differential: #{ratio}, reference: #{reference["count"]} @ #{reference["datetime"]}"
    end
end
