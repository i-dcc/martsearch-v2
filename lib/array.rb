# This is a small extension to the Array class to allow you 
# to iterate over an array in chunks of a defined size.
#
# Taken from "Why's (Poignant) Guide to Ruby" (http://poignantguide.net/ruby).
class Array
  # Splits an array into an array-of-arrays of the defined length
  def chunk( len )
    a = []
    each_with_index do |x,i|
      a << [] if i % len == 0
      a.last << x
    end
    a
  end
end
