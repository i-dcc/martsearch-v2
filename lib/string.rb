# This is a small extension to the String class to allow pretty 
# formatting of text...
class String
  def titlecase
    small_words = %w(a an and as at but by en for if in of on or the to v v. via vs vs.)
    
    string = split(" ").map do |word|
      # note: word could contain non-word characters!
      # downcase all small_words, capitalize the rest
      small_words.include?(word.gsub(/\W/, "").downcase) ? word.downcase! : word.smart_capitalize!
      word
    end
    # capitalize first and last words
    string.first.smart_capitalize!
    string.last.smart_capitalize!
    # small words after colons are capitalized
    string.join(" ").gsub(/:\s?(\W*#{small_words.join("|")}\W*)\s/) { ": #{$1.smart_capitalize} " }
  end
  
  def smart_capitalize
    # ignore any leading crazy characters and capitalize the first real character
    if self =~ /^['"\(\[']*([a-z])/
      idx = index($1)
      string = self[idx,self.length]
      # word with capitals and periods mid-word are left alone
      self[idx,1] = self[idx,1].upcase unless string =~ /[A-Z]/ or string =~ /\.\w+/
    end
    self
  end
  
  def smart_capitalize!
    replace(smart_capitalize)
  end
end