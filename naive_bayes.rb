class NaiveBayes
  COMMON_WORDS = ['a','able','about','above','abroad']
  FILE_PATH = "/settings/"

  def saveYaml(variable, name)
    log = File.open( Dir.pwd + FILE_PATH + name + ".yaml" ,'w+') do |f|
          f.puts variable.to_yaml
    end
  end

  def getYaml(name)
    if(File.exist?(Dir.pwd + FILE_PATH + name + ".yaml") == false)
      return nil
    end
    return YAML::load( File.open( Dir.pwd + FILE_PATH + name + ".yaml", 'r') )
  end

  def exportData
    saveYaml(@words,"words")
    saveYaml(@total_words,"total_words")
    saveYaml(@categories_documents,"categories_documents")
    saveYaml(@total_documents,"total_documents")
    saveYaml(@categories_words,"categories_words")
    saveYaml(@threshold,"threshold")
  end

  def importData
    @words = getYaml("words")
    @total_words = getYaml("total_words")
    @categories_documents = getYaml("categories_documents")
    @total_documents = getYaml("total_documents")
    @categories_words = getYaml("categories_words")
    @threshold = getYaml("threshold")
    if(@words != nil && @total_words != nil && @categories_documents!= nil &&
        @total_documents != nil && @categories_words!= nil && @threshold!= nil)
      return true
    end
    return false
  end

  def initialize(*categories)
    @words = Hash.new
    @total_words = 0
    @categories_documents = Hash.new
    @total_documents = 0
    @categories_words = Hash.new
    @threshold = 1.5
    hi = importData
    if(hi != true)
      @words = Hash.new
      @total_words = 0
      @categories_documents = Hash.new
      @total_documents = 0
      @categories_words = Hash.new
      @threshold = 1.5
      categories.each { |category|
        @words[category] = Hash.new
        @categories_documents[category] = 0
        @categories_words[category] = 0
      }
    end
    puts @words.to_s
    puts @total_words
    puts @categories_documents.to_s
    puts @total_documents
    puts @categories_words.to_s
    puts @threshold
  end

  def word_count(document)
   words = document.gsub(/[^\w\s]/,"").split
   d = Hash.new
   words.each do |word|
    word.downcase!
    key = word.stem
    unless COMMON_WORDS.include?(word)
      d[key] ||= 0
      d[key] += 1
    end
   end
   return d
  end

  def train(category, document)
    word_count(document).each do |word, count|
      #puts category, word , count
      @words[category][word] ||= 0
      @words[category][word] += count
      @total_words += count
      @categories_words[category] += count
    end
    @categories_documents[category] += 1
    @total_documents += 1

  end

  def classify(document, default='unknown')
    sorted = probabilities(document).sort {|a,b| a[1]<=>b[1]}
    best,second_best = sorted.pop, sorted.pop
    return best[0] if (best[1]/second_best[1] > @threshold)
    return default
  end

=begin
**************************************
*    probability counting methods    *
**************************************
=end

  def category_probability(category)
    @categories_documents[category].to_f/@total_documents.to_f
  end

  def word_probability(category, word)
    (@words[category][word.stem].to_f + 1)/@categories_words[category].to_f
  end

  def doc_probability(category, document)
    doc_prob = 1
    word_count(document).each { |word| doc_prob *= word_probability(category, word[0]) }
    return doc_prob
  end

  def probability(category, document)
    doc_probability(category, document) * category_probability(category)
  end

  def probabilities(document)
    probabilities = Hash.new
    @words.each_key {|category|
      probabilities[category] = probability(category, document)
    }
    return probabilities
  end

end