class String
  def humanize
    self.split(/_|-| /).join(' ')
  end
  
  def titleize
    self.split(/_|-| /).each{|word| word[0...1] = word[0...1].upcase}.join(' ')
  end
  
  def empty?
    self.length < 1
  end
end

class NilClass
  def empty?
    true
  end
end

class Array
  def empty?
    self.length < 1
  end
end

class Hash
  def empty?
    self.length < 1
  end
end    

class Symbol
  def titleize
    self.to_s.titleize
  end
end
