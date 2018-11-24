
# encoding: UTF-8

DAYNOTES_FILEPATH = "/Users/pascal/Desktop/DayNotes.txt"

class NSXDayNotes

	# NSXDayNotes::displayOrNull()
	def self.displayOrNull()
        filecontents = IO.read(DAYNOTES_FILEPATH)
        firstPart = filecontents.split('@after-today').first.strip
        return nil if firstPart.size==0
        firstPart
	end

	# NSXDayNotes::deleteFirstLine()
	def self.deleteFirstLine()
		filecontents = IO.read(DAYNOTES_FILEPATH)
		filecontents = filecontents.lines.drop(1).join()
		File.open(DAYNOTES_FILEPATH, "w"){|f| f.puts(filecontents) }
	end

end

