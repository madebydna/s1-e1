#require 'wordnik_service'

class Thesaurus
  
  WordNotFoundError = Class.new(StandardError) 
  NoSynonymError = Class.new(StandardError)
  
  
  WORD_TYPES = ["verb", "noun", "adjective", "adverb"]
  REL_TYPES = %w[equivalent synonym hyponym hyernym same-context]
  
  def initialize(wordnik_service)
    @wordnik_service = wordnik_service
  end
  
  def lookup_synonyms(word)
    @type, @word = parse_message(word)
    options = @type ? {:partOfSpeech => @type } : {}
    handle_result(@wordnik_service.do_request("word.json/#{@word.downcase}/related", options))
    rescue WordNotFoundError => e
      e.message
    rescue NoSynonymError => e
      #raise e.inspect
      e.message
  end
  
  def parse_result(response)
    # response is array of hashes
    synonyms = []
    response.map do |wordshash|
      synonyms << wordshash["wordstrings"] if REL_TYPES.include?(wordshash["relType"])
    end
    return err_message if synonyms.empty?
    enforce_twitter_limit(synonyms)
  end
    
  
  def enforce_twitter_limit(synonyms)
    str = synonyms.join(", ")
    answer = str.length < 140 ? str : shorten_string(str)
    return answer
    # TODO: send multiple messages if respose exceeds Twitter limit 
  end
  
  def shorten_string(str)
    str = str[0..140]
    #lose the last comma if it is there
    if str.strip[/,$/]
      str = str.chop
    end
  end
  
  def parse_message(word)
    arr = word.split.collect { |s| s.strip[/\w+/]}
    if WORD_TYPES.include?(arr.last) 
      [arr.delete(arr.last), arr.last]
    else
      [nil, arr.last]
    end
  end
  
  private
  
  def handle_result(result)
    result = result.parsed_response
    if result.is_a?(Hash) && result.key?('type') && result['type'] == 'error'
      raise WordNotFoundError, err_message 
    elsif result == []
      raise NoSynonymError, err_message
    else
      parse_result(result)
    end
  end
  
  def err_message
    err =  "No synonyms found for #{@word}"
    err += "/#{@type}" if @type
    return err
  end
  
end

#t = Thesaurus.new(WordnikService.new)
#answer = t.lookup_synonyms('hjp verb')
#puts answer