module MotionModel
  module InputHelpers
    class ModelNotSetError < RuntimeError; end
    
    # FieldBindingMap contains a simple label to model
    # field binding, and is decorated by a tag to be
    # used on the UI control.
    class FieldBindingMap
      attr_accessor :label, :name, :tag
      
      def initialize(options = {})
        @name = options[:name]
        @label = options[:label]
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set('@binding_data', [])
    end
    
    module ClassMethods
      # +field+ is a declarative macro that specifies
      # the field name (i.e., the model field name)
      # and the label. In the absence of a label,
      # +field+ attempts to synthesize one from the
      # model field name. YMMV.
      #
      # Usage:
      #
      #    class MyInputSheet < UIViewController
      #      include InputHelpers
      #
      #      field 'event_name', :label => 'name'
      #      field 'event_location', :label => 'location
      #
      # Only one field mapping may be supplied for
      # a given class.
      def field(field, options = {})
        label = options[:label] || field.humanize
        @binding_data << FieldBindingMap.new(:label => label, :name => field)
      end
    end
    
    # +model+ is a mandatory method in which you
    # specify the instance of the model to which
    # your fields are bound.
    
    def model(model_instance)
      @model = model_instance
    end
    
    # +field_count+ specifies how many fields have
    # been bound.
    #
    # Usage:
    #
    #     def tableView(table, numberOfRowsInSection: section)
    #       field_count
    #     end

    def field_count
      self.class.instance_variable_get('@binding_data'.to_sym).length
    end

    # +field_at+ retrieves the field at a given index.
    #
    # Usage:
    #  
    #     field = field_at(indexPath.row)
    #     label_view = subview(UILabel, :label_frame, text: field.label)
    
    def field_at(index)
      data = self.class.instance_variable_get('@binding_data'.to_sym)
      data[index].tag = index + 1
      data[index]
    end

    # +value_at+ retrieves the value from the form that corresponds
    # to the name of the field.
    #
    # Usage:
    #
    #     value_edit_view = subview(UITextField, :input_value_frame, text: value_at(field))

    def value_at(field)
      @model.send(field.name)
    end
    
    # +fields+ is the iterator for all fields
    # mapped for this class.
    #
    # Usage:
    #
    #     fields do |field|
    #       do_something_with field.label, field.value
    #     end
    
    def fields
      self.class.instance_variable_get('@binding_data'.to_sym).each{|datum| yield datum}
    end
    
    # +bind+ fetches all mapped fields from
    # any subview of the current +UIView+
    # and transfers the contents to the
    # corresponding fields of the model
    # specified by the +model+ method.
    def bind
      raise ModelNotSetError.new("You must set the model before binding it.") unless @model
      
      fields do |field|
        view_obj = self.view.viewWithTag(field.tag)
        @model.send("#{field.name}=".to_sym, view_obj.text)
      end
    end

    # Handle hiding the keyboard if the user
    # taps "return". If you don't want this behavior,
    # define the function as empty in your class.
    def textFieldShouldReturn(textField)
      textField.resignFirstResponder
    end

    # Keyboard show/hide handlers do this:
    #
    # * Reset the table insets so that the
    #   UITableView knows how large its real
    #   visible area.
    # * Scroll the UITableView to reveal the
    #   cell that has the +firstResponder+
    #   if it is not already showing.
    #
    # Of course, the process is exactly reversed
    # when the keyboard hides.
    #
    # An instance variable +@table+ is assumed to
    # be the table to affect; if this is missing,
    # this code will simply no-op.
    #
    # Rejigger everything under the sun when the
    # keyboard slides up.
    #
    # You *must* handle the +UIKeyboardWillShowNotification+ and
    # when you receive it, call this method to handle the keyboard
    # showing.
    def handle_keyboard_will_show(notification)
      return unless @table

      animationCurve = notification.userInfo.valueForKey(UIKeyboardAnimationCurveUserInfoKey)
      animationDuration = notification.userInfo.valueForKey(UIKeyboardAnimationDurationUserInfoKey)
      keyboardEndRect = notification.userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey)
      
      keyboardEndRect = view.convertRect(keyboardEndRect.CGRectValue, fromView:App.delegate.window)

      UIView.beginAnimations "changeTableViewContentInset", context:nil
      UIView.setAnimationDuration animationDuration
      UIView.setAnimationCurve animationCurve

      intersectionOfKeyboardRectAndWindowRect = CGRectIntersection(App.delegate.window.frame, keyboardEndRect)
      bottomInset = intersectionOfKeyboardRectAndWindowRect.size.height;
    
      @table.contentInset = UIEdgeInsetsMake(0, 0, bottomInset, 0)

      # Find active cell
      indexPathOfOwnerCell = nil
      numberOfCells = @table.dataSource.tableView(@table, numberOfRowsInSection:0)
      0.upto(numberOfCells) do |index|
        indexPath = NSIndexPath.indexPathForRow(index, inSection:0)
        cell = @table.cellForRowAtIndexPath(indexPath)
        if cell_has_first_responder?(cell)
          indexPathOfOwnerCell = indexPath
          break
        end
      end

      UIView.commitAnimations

      if indexPathOfOwnerCell
        @table.scrollToRowAtIndexPath(indexPathOfOwnerCell, 
          atScrollPosition:UITableViewScrollPositionMiddle,
          animated: true)
      end
    end

    # Undo all the rejiggering when the keyboard slides
    # down.
    #
    # You *must* handle the +UIKeyboardWillHideNotification+ and
    # when you receive it, call this method to handle the keyboard
    # hiding.
    def handle_keyboard_will_hide(notification)
      return unless @table

      if UIEdgeInsetsEqualToEdgeInsets(@table.contentInset, UIEdgeInsetsZero)
        return
      end
    
      animationCurve = notification.userInfo.valueForKey(UIKeyboardAnimationCurveUserInfoKey)
      animationDuration = notification.userInfo.valueForKey(UIKeyboardAnimationDurationUserInfoKey)
    
      UIView.beginAnimations("changeTableViewContentInset", context:nil)
      UIView.setAnimationDuration(animationDuration)
      UIView.setAnimationCurve(animationCurve)
    
      @table.contentInset = UIEdgeInsetsZero;
    
      UIView.commitAnimations    
    end
    
    def cell_has_first_responder?(cell)
      cell.subviews.each do |subview|
        return true if subview.isFirstResponder
      end
      false
    end
  end
end
