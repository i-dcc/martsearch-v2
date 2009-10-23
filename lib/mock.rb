# Class for making dynamic mocks.
#
# Used to allow the Dataset sorting routines to be dynamically
# overriden on a per-datasource basis.
#
# Code borrowed from:
# http://michal.hantl.cz/how-to-override-ruby-object-methods-dynamically/
class Mock

  # Mocks (overrides) method using new_method,
  # returns duplicate instance.
  #
  # It is possible to mock again and again.
  # We get cloned instance each time.
  #
  #  hello = Magic.Mock.method("hello", :to_s) do
  #    super().reverse
  #  end
  #
  #  hello.to_s # returns "olleh"
  #
  def self.method instance, method_name, &new_method
    i = instance.clone
    i.extend(Module.new { define_method(method_name, &new_method) })
    i
  end
end
