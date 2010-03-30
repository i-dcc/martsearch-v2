# This is a small extension to the Array class to allow you 
# to iterate over an array in chunks of a defined size.
#
# Taken from "Why's (Poignant) Guide to Ruby" (http://poignantguide.net/ruby).
class Array
  # Splits an array into an array-of-arrays of the defined length
  def chunk( length )
    chunks = []
    each_with_index do |element,index|
      chunks << [] if index % length == 0
      chunks.last << element
    end
    chunks
  end
end
