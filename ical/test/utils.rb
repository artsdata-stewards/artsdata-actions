
module Utils
  def self.replace_federated_service_call(str, replacement_text)
    start_tag = 'SERVICE <https://query.wikidata.org/sparql>'
    start = str.index(start_tag)
    return str unless start
    depth = 0
    str.chars.each_with_index do |char, i|
      if i > start + start_tag.length
        depth += 1 if char == '{'
        depth -= 1 if char == '}'
        if depth == 0
          # Replace from first { to matching }
          return str[0...start] + replacement_text + str[(i + 1)..-1]
        end
      end
    end
    str # Return original if no matching closing brace
  end
end


