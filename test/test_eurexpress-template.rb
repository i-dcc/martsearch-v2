# require File.dirname(__FILE__) + '/test_helper.rb'
# 
# class EurexpressDatasetTest < Test::Unit::TestCase
#   context "The Eurexpress dataset" do
#     should "return data for a search on 'Cbx1'" do
#       results = test_eurexpress_search( "Cbx1" )
#       assert( results["Cbx1"], "The Eurexpress dataset did not return data for Cbx1." )
#     end
#     
#     should "not return data for a search on 'Mysm1'" do
#       results = test_eurexpress_search( "Mysm1" )
#       assert( results["Mysm1"].nil?, "The Eurexpress dataset returned data for Mysm1." )
#     end
#   end
#   
#   def test_eurexpress_search( query )
#     # Query the index
#     results = @@ms.index.search( query )
#     
#     assert_not_equal( results, false, "The .search function failed." )
#     assert( results.is_a?(Hash), ".search does not return a hash object." )
#     assert( @@ms.index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
#     
#     # Now fetch the pre-computed biomart search terms 
#     search_terms = @@ms.index.grouped_terms[ @@ms.datasets_by_name[:"eurexpress-template"].joined_index_field ]
#     if search_terms
#       assert( search_terms.is_a?(Array), "The retrieved search terms are not in an array." )
#     else
#       assert( search_terms.nil?, "The retrieved search terms is nil" )
#     end
#     
#     mart_results = @@ms.datasets_by_name[:"eurexpress-template"].search( search_terms )
#     assert( mart_results.is_a?(Hash), "The Biomart results are not in a hash." )
#     
#     return mart_results
#   end
# end