module MotionModel
  module Formotion
    FORMOTION_MAP = {
      :string   => :string,
      :date     => :date,
      :int      => :number,
      :integer  => :number,
      :float    => :number,
      :double   => :number,
      :bool     => :check,
      :boolean  => :check,
      :text     => :text
    }

    def returnable_columns
      cols = columns.select do |column|
        exposed = @expose_auto_date_fields ? true : ![:created_at, :updated_at].include?(column)
        column != :id &&                # don't ship back id by default
        !relation_column?(column) &&    # don't ship back relations -- formotion doesn't get them
        exposed                         # don't expose auto_date fields unless specified
      end
      cols
    end

    def to_formotion(section_title = nil, expose_auto_date_fields = false)
      @expose_auto_date_fields = expose_auto_date_fields
      form = {
        sections: [{}]
      }

      section = form[:sections].first
      section[:title] ||= section_title
      section[:rows] = []

      returnable_columns.each do |column|
        value = self.send(column)
        value = value.to_f if type(column) == :date && value
        h = {:key         => column.to_sym,
             :title       => column.to_s.humanize,
             :type        => FORMOTION_MAP[type(column)],
             :placeholder => column.to_s.humanize,
             :value       => value
             }
        options = column_named(column).options[:formotion]
        h.merge!(options) if options
        section[:rows].push h
      end
      form
    end
    
    def from_formotion!(data)
      self.returnable_columns.each{|column| self.send("#{column}=", data[column])}
    end
  end
end
