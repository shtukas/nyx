
# encoding: UTF-8

=begin

Struct2 [
    Array[String] # Individual strings are sections
    String
]

=end

class NSXLucilleCalendarFileUtils

    # NSXLucilleCalendarFileUtils::sectionToSectionUUID(section)
    def self.sectionToSectionUUID(section)
        Digest::SHA1.hexdigest(section.strip)[0, 8]
    end

    # NSXLucilleCalendarFileUtils::fileContentsToStruct1(content) : [Part, Part]
    def self.fileContentsToStruct1(content)
        content.split(LUCILLE_FILE_MARKER)
    end

    # NSXLucilleCalendarFileUtils::fileContentsToStruct2(content) : [Array[Section], Part]
    def self.fileContentsToStruct2(content)
        parts = NSXLucilleCalendarFileUtils::fileContentsToStruct1(content)
        [
            SectionsType0141::contentToSections(parts[0].lines.to_a),
            parts[1]
        ]
    end

    # NSXLucilleCalendarFileUtils::struct2ToFileContent(struct2)
    def self.struct2ToFileContent(struct2)
        [
            struct2[0].map{|str| str.strip}.join("\n").strip,
            "\n\n",
            LUCILLE_FILE_MARKER,
            struct2[1]
        ].join()
    end

    # NSXLucilleCalendarFileUtils::commitStruct2ToDisk(struct2)
    def self.commitStruct2ToDisk(struct2)
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        File.open(filepath, "w") { |io| io.puts(NSXLucilleCalendarFileUtils::struct2ToFileContent(struct2)) }
    end

    # NSXLucilleCalendarFileUtils::applyNextTransformationToStruct2(struct2)
    def self.applyNextTransformationToStruct2(struct2)
        return struct2 if struct2[0].empty?
        struct2[0][0] = NSXMiscUtils::applyNextTransformationToContent(struct2[0][0])
        struct2
    end

    # NSXLucilleCalendarFileUtils::getStruct()
    def self.getStruct()
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        NSXLucilleCalendarFileUtils::fileContentsToStruct2(IO.read(filepath))
    end

    # NSXLucilleCalendarFileUtils::commitFileCopyToBin()
    def self.commitFileCopyToBin()
        filepath = "/Users/pascal/Desktop/Calendar.txt"
        NSXMiscUtils::copyLocationToCatalystBin(filepath)
    end

    # NSXLucilleCalendarFileUtils::writeANewLucilleFileWithoutThisSectionUUID(uuid)
    def self.writeANewLucilleFileWithoutThisSectionUUID(uuid)
        NSXLucilleCalendarFileUtils::commitFileCopyToBin()
        struct2 = NSXLucilleCalendarFileUtils::getStruct()
        struct2[0] = struct2[0].reject{|section|
            NSXLucilleCalendarFileUtils::sectionToSectionUUID(section) == uuid
        }
        NSXLucilleCalendarFileUtils::commitStruct2ToDisk(struct2)
    end

    # NSXLucilleCalendarFileUtils::applyNextTransformationToLucilleFile()
    def self.applyNextTransformationToLucilleFile()
        NSXLucilleCalendarFileUtils::commitFileCopyToBin()
        struct2 = NSXLucilleCalendarFileUtils::getStruct()
        struct2 = NSXLucilleCalendarFileUtils::applyNextTransformationToStruct2(struct2)
        NSXLucilleCalendarFileUtils::commitStruct2ToDisk(struct2)
    end

    # NSXLucilleCalendarFileUtils::injectNewLineInPart1OfTheFile(line)
    def self.injectNewLineInPart1OfTheFile(line)
        NSXLucilleCalendarFileUtils::commitFileCopyToBin()
        struct2 = NSXLucilleCalendarFileUtils::getStruct()
        sections = struct2[0]
        sections << line
        struct2[0] = sections
        NSXLucilleCalendarFileUtils::commitStruct2ToDisk(struct2)
    end

end
