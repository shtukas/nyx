
# encoding: UTF-8

class DisplayUtils

    # DisplayUtils::defaultCatalystObjectCommands()
    def self.defaultCatalystObjectCommands()
        ["expose"]
    end

    # DisplayUtils::makeDisplayStringForCatalystListing(object)
    def self.makeDisplayStringForCatalystListing(object)
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

    # DisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/Miscellaneous::screenWidth()).ceil }.inject(0, :+)
    end
end