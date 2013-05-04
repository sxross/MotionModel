MotionSupport::Inflector.inflections do |inflect|
  inflect.plural    /^(\w+)us$/i, '\1i'
  inflect.singular  /^(\w+)i$/i, '\1us'

  inflect.singular  /^(\w+)ees$/i, '\1ee'
  inflect.singular  /^(\w+)es$/i, '\1e'
  inflect.singular  /^(\w+)sses$/i, '\1ss'
  inflect.plural    /^(\w+)ss$/i, '\1sses'
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
