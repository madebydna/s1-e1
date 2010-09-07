require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Thesaurus)

class ThesaurusTest < Test::Unit::TestCase 
  
  setup do
    @wordnik_service = mock("WordnikService")
    @thesaurus = Thesaurus.new(@wordnik_service)
  end
  
  context "looking up an existing word" do
    
    test "can find single word and return its synonyms" do
      setup_mock_for_ok_words('old', {}, 'simple_word')
      answer = @thesaurus.lookup_synonyms('old')
      assert_equal "grizzly, echt, over-the-hill, senescent, white-haired, yellow, rusty, overage, used, venerable", answer
    end
    
    test "can find word by type if specified to be a noun" do
      setup_mock_for_ok_words('work', {:partOfSpeech => "verb"}, 'word_as_verb')
      answer = @thesaurus.lookup_synonyms('work verb')
      assert_equal "toil, lobor, exert oneself, slave (away), slog, plug away, be employed, have a job, earn one's living, accomplish", answer
    end
    
    test "can find word by type if specified to be a verb" do
      setup_mock_for_ok_words('work', {:partOfSpeech => "noun"}, 'word_as_noun')
      answer = @thesaurus.lookup_synonyms('work noun')
      assert_equal "toil, slog, drudgery, exertion, effort, industry, service, grind, sweat, elbow grease", answer
    end
    
    test "rescues WordNotFoundError if word not found" do
      @wordnik_service.expects(:do_request).
                       with("word.json/sgfjshdfgds/related", {}).
                       returns(word_not_found)
       answer = @thesaurus.lookup_synonyms('sgfjshdfgds')
       assert_equal "No synonyms found for sgfjshdfgds", answer   
    end
    
    test "rescues NoSynonymError if there are no synonyms for a word" do
      @wordnik_service.expects(:do_request).
                       with("word.json/arroyo/related", {}).
                       returns(word_with_no_synonyms)
       answer = @thesaurus.lookup_synonyms('arroyo')
       assert_equal "No synonyms found for arroyo", answer   
    end
    
  end
  
  def setup_mock_for_ok_words(word, options, file_to_read)
    @wordnik_service.expects(:do_request).
                     with("word.json/#{word}/related", options).
                     returns(found_word(file_to_read))
  end

  
  def found_word(filename)
    stub('HTTParty::Response') do
      stubs(:parsed_response).returns(fixture_file(filename))
    end
  end
  
  def word_not_found
    stub('HTTParty::Response') do
      stubs(:parsed_response).returns({"message" => "word not found", "type" => "error"})
    end
  end
  
  def word_with_no_synonyms
    stub('HTTParty::Response') do
      stubs(:parsed_response).returns([])
    end
  end
  
end