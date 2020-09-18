
# encoding: UTF-8

class OperatingMode

    # OperatingMode::current()
    def self.current() # "regular" | "work"
        if [1, 2, 3, 4, 5].include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 17 then
            return "work"
        end
        "regular"
    end

    # OperatingMode::isWork?()
    def self.isWork?()
        OperatingMode::current() == "work"
    end
end

