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
  
  def pluralize
    Inflector.inflections.pluralize self
  end
  
  def singularize
    Inflector.inflections.singularize self
  end
end

# Inflector is a singleton class that helps
# singularize, pluralize and other-thing-ize
# words. It is very much based on the Rails
# ActiveSupport implementation or Inflector
class Inflector
  def self.instance
    @__instance__ ||= new
  end
  
  def initialize
    reset
  end
  
  def reset
    # Put singular-form to plural form transformations here
    @plurals = [
      [/^person$/, 'people'],
      [/^identity$/, 'identities'],
      [/^child$/, 'children'],
      [/^(.*)ee$/i, '\1ees'],     # attendee => attendees
      [/^(.*)us$/i, '\1i'],       # alumnus  => alumni
      [/^(.*s)$/i, '\1es'],       # pass     => passes
      [/^(.*)$/, '\1s']           # normal   => normals
    ]

    # Put plural-form to singular form transformations here
    @singulars = [
      [/^people$/, 'person'],
      [/^identities$/, 'identity'],
      [/^children$/, 'child'],
      [/^(.*)ees$/i, '\1ee'],     # attendees  => attendee
      [/^(.*)es$/i, '\1'],        # passes     => pass
      [/^(.*)i$/i, '\1us'],       # alumni     => alumnus
      [/^(.*)s$/i, '\1']          # normals    => normal
    ]
    
    @irregulars = [
    ]
    
    @uncountables = [
      'fish',
      'sheep'
    ]
  end
  
  attr_reader :plurals, :singulars, :uncountables, :irregulars
  
  def self.inflections
    if block_given?
      yield Inflector.instance
    else
      Inflector.instance
    end
  end
      
  def uncountable(word)
    @uncountables << word
  end
  
  def singular(rule, replacement)
    @singulars << [rule, replacement]
  end
  
  def plural(rule, replacement)
    @plurals << [rule, replacement]
  end
  
  def irregular(rule, replacement)
    @irregulars << [rule, replacement]
  end
  
  def uncountable?(word)
    return word if @uncountables.include?(word.downcase)
    false
  end
  
  def singularize(word)
    return word if uncountable?(word)
    plural = word.dup
    
    @irregulars.each do |rule|
      return plural if plural.gsub!(rule.first, rule.last)
    end
    
    @singulars.each do |rule|
      return plural if plural.gsub!(rule.first, rule.last)
    end
    plural
  end
  
  def pluralize(word)
    return word if uncountable?(word)
    singular = word.dup
    
    @irregulars.each do |rule|
      return singular if singular.gsub!(rule.first, rule.last)
    end
    
    @plurals.each do |rule|
      return singular if singular.gsub!(rule.first, rule.last)
    end
    singular
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

class Ansi
  ESCAPE = "\033"
  
  def self.color(color_constant)
    "#{ESCAPE}[#{color_constant}m"
  end
  
  def self.reset_color
    color 0
  end
  
  def self.yellow_color
    color 33
  end
  
  def self.green_color
    color 32
  end
  
  def self.red_color
    color 31
  end
end

class Debug
  @@silent = false
  @@colorize = true
  
  # Use silence if you want to keep messages from being echoed
  # to the console.
  def self.silence
    @@silent = true
  end
  
  def self.colorize
    @@colorize
  end
  
  def self.colorize=(value)
    @@colorize = value == true
  end
  
  # Use resume when you want messages that were silenced to
  # resume displaying.
  def self.resume
    @@silent = false
  end
  
  def self.put_message(type, message, color = Ansi.reset_color)
    open_color = @@colorize ? color : ''
    close_color = @@colorize ? Ansi.reset_color : ''
    
    NSLog("#{open_color}#{type} #{caller[1]}: #{message}#{close_color}") unless @@silent
  end
  
  def self.info(msg)
    put_message 'INFO', msg, Ansi.green_color
  end
  
  def self.warning(msg)
    put_message 'WARNING', msg, Ansi.yellow_color
  end
  
  def self.error(msg)
    put_message 'ERROR', msg, Ansi.red_color
  end
  
end

# These are C macros in iOS SDK. Not workable for Ruby.
def UIInterfaceOrientationIsLandscape(orientation)
  orientation == UIInterfaceOrientationLandscapeLeft ||
     orientation == UIInterfaceOrientationLandscapeRight
end

def UIInterfaceOrientationIsPortrait(orientation)
  orientation == UIInterfaceOrientationPortrait ||
     orientation == UIInterfaceOrientationPortraitUpsideDown
end
