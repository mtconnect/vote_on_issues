require 'query'

class VOI_QueryColumn < QueryColumn
  def value(object)
    object.send name, object
  end

  def value_object(object)
    object.send name, object
  end
end
