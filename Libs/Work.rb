
# encoding: UTF-8

class Work
    # Work::shouldBeTheFocus()
    def self.shouldBeTheFocus()
        (1..5).include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 17
    end
end
