# -*- coding: utf-8 -*-
class NilClass
  def blank?
    true
  end
end

class Object
  # Call method on object if-and-only-if the object is not nil.
  #
  # method_name - name of the method to call
  # *args - (optional) list of arguments to pass to the call.
  #
  # Example
  #     object.try(:strftime, "%y")
  #     => nil
  #
  # Returns nil if the object was nil or if the method call returned nil.
  def try(method_name, *args)
    nil? ? nil : send(method_name, *args)
  end

  # Test the blankness of a string. A string is blank if it's Nil or
  # if it's empty, i.e. "".
  #
  # No Argument
  #
  # Example
  #     "".blank?
  #     => true
  #
  # This converts the object to its string representation and checks whether that
  # is blank. Nil is blank because its string representation is "".
  def blank?
    to_s.blank?
  end
end
