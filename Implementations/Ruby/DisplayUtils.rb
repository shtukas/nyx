
# encoding: UTF-8

class DisplayUtils
    # DisplayUtils::makeDisplayStringForCatalystListingCore(object)
    def self.makeDisplayStringForCatalystListingCore(object)
        body = object["body"]
        lines = body.lines.to_a
        ordinalPrefix = 
            if object["::ordinal"] then
                "(ordinal: #{object["::ordinal"]})".green
            else
                ""
            end
        prefix = 
            if ordinalPrefix.size > 0 then
                "#{ordinalPrefix} "
            else
                "(#{"%5.3f" % object["metric"]}) "
            end
        if lines.size == 1 then
            "#{prefix}#{lines.first}"
        else
            "#{prefix}#{lines.shift}" + lines.map{|line|  "             #{line}"}.join()
        end
    end

    # DisplayUtils::makeDisplayStringForCatalystListing(object)
    def self.makeDisplayStringForCatalystListing(object)
        text = DisplayUtils::makeDisplayStringForCatalystListingCore(object)
        if object["isRunning"] then
            text = text.green
        end
        text
    end

    # DisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (((line.size+5).to_f)/Miscellaneous::screenWidth()).ceil }.inject(0, :+)
    end
end