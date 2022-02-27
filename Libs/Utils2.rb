
# encoding: UTF-8

# -----------------------------------------------------------------------

class ItemStore
    def initialize() # : Integer
        @items = []
    end
    def add(item)
        cursor = @items.size
        @items << item
        cursor 
    end
    def get(indx)
        @items[indx].clone
    end
end

class Utils2

    # Utils2::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.hex
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # Utils2::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # Utils2::isDateTime_UTC_ISO8601(datetime)
    def self.isDateTime_UTC_ISO8601(datetime)
        begin
            DateTime.parse(datetime).to_time.utc.iso8601 == datetime
        rescue
            false
        end
    end

    # Utils2::updateDateTimeWithANewDate(datetime, date)
    def self.updateDateTimeWithANewDate(datetime, date)
        datetime = "#{date}#{datetime[10, 99]}"
        if !Utils2::isDateTime_UTC_ISO8601(datetime) then
            raise "(error: 32c505fa-4168, #{datetime})"
        end
        datetime
    end

    # Utils2::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # Utils2::openUrl(url)
    def self.openUrl(url)
        system("open -a Safari '#{url}'")
    end

    # Utils2::locationByUniqueStringOrNull(uniquestring)
    def self.locationByUniqueStringOrNull(uniquestring)
        location = `atlas '#{uniquestring}'`.strip
        location.size > 0 ? location : nil
    end

    # Utils2::sanitiseStringForFilenaming(str)
    def self.sanitiseStringForFilenaming(str)
        str
            .gsub(":", "-")
            .gsub("/", "-")
            .gsub("'", "")
            .strip
    end

    # ----------------------------------------------------

    # Utils2::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1] # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # Utils2::stringDistance1(str1, str2)
    def self.stringDistance1(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        Utils2::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # Utils2::stringDistance2(str1, str2)
    def self.stringDistance2(str1, str2)
        # We need the smallest string to come first
        if str1.size > str2.size then
            str1, str2 = str2, str1
        end
        diff = str2.size - str1.size
        (0..diff).map{|i| Utils2::levenshteinDistance(str1, str2[i, str1.size]) }.min
    end

    # ----------------------------------------------------

    # Utils2::selectLinesUsingInteractiveInterface(lines) : Array[String]
    def self.selectLinesUsingInteractiveInterface(lines)
        # Some lines break peco, so we need to be a bit clever here...
        linesX = lines.map{|line|
            {
                "line"     => line,
                "announce" => line.gsub("(", "").gsub(")", "").gsub("'", "").gsub('"', "") 
            }
        }
        announces = linesX.map{|i| i["announce"] } 
        selected = `echo '#{([""]+announces).join("\n")}' | /usr/local/bin/peco`.split("\n")
        selected.map{|announce| 
            linesX.select{|i| i["announce"] == announce }.map{|i| i["line"] }.first 
        }
        .compact
    end

    # Utils2::selectLineOrNullUsingInteractiveInterface(lines) : String
    def self.selectLineOrNullUsingInteractiveInterface(lines)
        lines = Utils2::selectLinesUsingInteractiveInterface(lines)
        if lines.size == 0 then
            return nil
        end
        if lines.size == 1 then
            return lines[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("select", lines)
    end

    # Utils2::selectOneObjectUsingInteractiveInterfaceOrNull(items, toString = lambda{|item| item })
    def self.selectOneObjectUsingInteractiveInterfaceOrNull(items, toString = lambda{|item| item })
        lines = items.map{|item| toString.call(item) }
        line = Utils2::selectLineOrNullUsingInteractiveInterface(lines)
        return nil if line.nil?
        items
            .select{|item| toString.call(item) == line }
            .first
    end
end
