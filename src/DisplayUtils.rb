
# encoding: UTF-8

class DisplayUtils

    # DisplayUtils::defaultCatalystObjectCommands()
    def self.defaultCatalystObjectCommands()
        ["expose"]
    end

    # DisplayUtils::makeDisplayStringForCatalystListingCore(object)
    def self.makeDisplayStringForCatalystListingCore(object)
        # Miscellaneous::screenWidth()
        body = object["body"]
        lines = body.lines.to_a
        if lines.size == 1 then
            "(#{"%5.3f" % object["metric"]}) #{lines.first}"
        else
            first = lines.shift
            "(#{"%5.3f" % object["metric"]}) #{first}" + lines.map{|line|  "             #{line}"}.join()
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
        displayStr.lines.map{|line| (line.size.to_f/Miscellaneous::screenWidth()).ceil }.inject(0, :+)
    end
end