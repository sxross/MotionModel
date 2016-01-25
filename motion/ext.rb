# The reason the String extensions are wrapped in
# conditional blocks is to reduce the likelihood
# of a namespace collision with other libraries.

class String
  unless String.instance_methods.include?(:humanize)
    def humanize
      self.split(/_|-| /).join(' ')
    end
  end

  unless String.instance_methods.include?(:titleize)
    def titleize
      self.split(/_|-| /).each{|word| word[0...1] = word[0...1].upcase}.join(' ')
    end
  end

  unless String.instance_methods.include?(:empty?)
    def empty?
      self.length < 1
    end
  end

  unless String.instance_methods.include?(:pluralize)
    def pluralize
      Inflector.inflections.pluralize self
    end
  end

  unless String.instance_methods.include?(:singularize)
    def singularize
      Inflector.inflections.singularize self
    end
  end

  unless String.instance_methods.include?(:camelize)
    def camelize(uppercase_first_letter = true)
      string = self.dup
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) do
        new_word = $2.downcase
        new_word[0] = new_word[0].upcase
        new_word = "/#{new_word}" if $1 == '/'
        new_word
      end
      if uppercase_first_letter && uppercase_first_letter != :lower
        string[0] = string[0].upcase
      else
        string[0] = string[0].downcase
      end
      string.gsub!('/', '::')
      string
    end
  end

  unless String.instance_methods.include?(:underscore)
    def underscore
      word = self.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end

  unless String.instance_methods.include?(:constantize)
    def constantize
      names = self.split('::'.freeze)

      # Trigger a built-in NameError exception including the ill-formed constant in the message.
      Object.const_get(self) if names.empty?

      # Remove the first blank element in case of '::ClassName' notation.
      names.shift if names.size > 1 && names.first.empty?

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if constant.const_defined?(name, false)
          next candidate unless Object.const_defined?(name)

          # Go down the ancestors to check if it is owned directly. The check
          # stops when we reach Object or the end of ancestors tree.
          constant = constant.ancestors.inject do |const, ancestor|
            break const    if ancestor == Object
            break ancestor if ancestor.const_defined?(name, false)
            const
          end

          # owner is in Object, so raise
          constant.const_get(name, false)
        end
      end
    end
  end
end

# Inflector is a singleton class that helps
# singularize, pluralize and other-thing-ize
# words. It is very much based on the Rails
# ActiveSupport implementation or Inflector
class Inflector
  def self.instance #nodoc
    @__instance__ ||= new
  end

  def initialize #nodoc
    reset
  end

  def reset
    # Put singular-form to plural form transformations here
    @plurals = [
      [/^person$/, 'people'],
      [/^man$/, 'men'],
      [/^child$/, 'children'],
      [/^sex$/, 'sexes'],
      [/^move$/, 'moves'],
      [/^cow$/, 'kine'],
      [/^zombie$/, 'zombies'],
      [/(quiz)$/i, '\1zes'],
      [/^(oxen)$/i, '\1'],
      [/^(ox)$/i, '\1en'],
      [/^(m|l)ice$/i, '\1ice'],
      [/^(m|l)ouse$/i, '\1ice'],
      [/(matr|vert|ind)(?:ix|ex)$/i, '\1ices'],
      [/(x|ch|ss|sh)$/i, '\1es'],
      [/([^aeiouy]|qu)y$/i, '\1ies'],
      [/(hive)$/i, '\1s'],
      [/(?:([^f])fe|([lr])f)$/i, '\1\2ves'],
      [/sis$/i, 'ses'],
      [/([ti])a$/i, '\1a'],
      [/([ti])um$/i, '\1a'],
      [/(buffal|tomat)o$/i, '\1oes'],
      [/(bu)s$/i, '\1ses'],
      [/(alias|status)$/i, '\1es'],
      [/(octop|vir)i$/i, '\1i'],
      [/(octop|vir|alumn)us$/i, '\1i'],
      [/^(ax|test)is$/i, '\1es'],
      [/s$/i, 's'],
      [/$/, 's']
    ]

    # Put plural-form to singular form transformations here
    @singulars = [
      [/^people$/, 'person'],
      [/^men$/, 'man'],
      [/^children$/, 'child'],
      [/^sexes$/, 'sex'],
      [/^moves$/, 'move'],
      [/^kine$/, 'cow'],
      [/^zombies$/, 'zombie'],
      [/(database)s$/i, '\1'],
      [/(quiz)zes$/i, '\1'],
      [/(matr)ices$/i, '\1ix'],
      [/(vert|ind)ices$/i, '\1ex'],
      [/^(ox)en/i, '\1'],
      [/(alias|status)(es)?$/i, '\1'],
      [/(octop|vir|alumn)(us|i)$/i, '\1us'],
      [/^(a)x[ie]s$/i, '\1xis'],
      [/(cris|test)(is|es)$/i, '\1is'],
      [/(shoe)s$/i, '\1'],
      [/(o)es$/i, '\1'],
      [/(bus)(es)?$/i, '\1'],
      [/^(m|l)ice$/i, '\1ouse'],
      [/(x|ch|ss|sh)es$/i, '\1'],
      [/(m)ovies$/i, '\1ovie'],
      [/(s)eries$/i, '\1eries'],
      [/([^aeiouy]|qu)ies$/i, '\1y'],
      [/([lr])ves$/i, '\1f'],
      [/(tive)s$/i, '\1'],
      [/(hive)s$/i, '\1'],
      [/([^f])ves$/i, '\1fe'],
      [/(^analy)(sis|ses)$/i, '\1sis'],
      [/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$/i, '\1sis'],
      [/([ti])a$/i, '\1um'],
      [/(n)ews$/i, '\1ews'],
      [/(ss)$/i, '\1'],
      [/s$/i, '']
    ]

    @irregulars = [
    ]

    @uncountables = [
      'equipment',
      'information',
      'rice',
      'money',
      'species',
      'series',
      'fish',
      'sheep',
      'jeans',
      'police'
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

  def inflect(word, direction) #nodoc
    return word if uncountable?(word)

    subject = word.dup

    @irregulars.each do |rule|
      return subject if subject.gsub!(rule.first, rule.last)
    end

    sense_group = direction == :singularize ? @singulars : @plurals
    sense_group.each do |rule|
      return subject if subject.gsub!(rule.first, rule.last)
    end
    subject
  end

  def singularize(word)
     inflect word, :singularize
  end

  def pluralize(word)
    inflect word, :pluralize
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

  # If any item in the array has the key == `key` true, otherwise false.
  # Of good use when writing specs.
  def has_hash_key?(key)
    self.each do |entity|
      return true if entity.has_key? key
    end
    return false
  end

  # If any item in the array has the value == `key` true, otherwise false
  # Of good use when writing specs.
  def has_hash_value?(key)
    self.each do |entity|
      entity.each_pair{|hash_key, value| return true if value == key}
    end
    return false
  end
end



class Hash
  def empty?
    self.length < 1
  end

  # Returns the contents of the hash, with the exception
  # of the keys specified in the keys array.
  def except(*keys)
    self.dup.reject{|k, v| keys.include?(k)}
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

class Module
  # Retrieve a constant within its scope
  def deep_const_get(const)
    if Symbol === const
      const = const.to_s
    else
      const = const.to_str.dup
    end
    if const.sub!(/^::/, '')
      base = Object
    else
      base = self
    end
    const.split(/::/).inject(base) { |mod, name| mod.const_get(name) }
  end
end
