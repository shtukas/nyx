
# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/SectionsType0141.rb"
# SectionsType0141::contentToSection(text)

# ---------------------------------------------------------------------------------------------

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# ---------------------------------------------------------------------------------------------

class SectionsType0141

    # SectionsType0141::contentToSections(text)
    def self.contentToSections(text)
        SectionsType0141::linesToSection(text.lines.to_a)
    end

    # SectionsType0141::linesToSection(reminaingLines)
    def self.linesToSection(reminaingLines, sections = [""])
        # presection: Array[String]
        if reminaingLines.size==0 then
            return sections
                .select{|section| section.strip.size>0 }
        end
        line = reminaingLines.shift
        if line.start_with?('[]') then
            sections << line
        else
            sections[sections.size-1] = sections[sections.size-1] + line
        end
        SectionsType0141::linesToSection(reminaingLines, sections)
    end
end

