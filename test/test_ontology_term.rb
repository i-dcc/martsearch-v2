require File.dirname(__FILE__) + '/test_helper.rb'

class OntologyTermTest < Test::Unit::TestCase
  context "An OntologyTerm object" do
    setup do
      @emap_id   = "EMAP:3018"
      @emap_name = "TS18,nose"
      @ont = OntologyTerm.new(@emap_id)
    end
    
    should "have basic attributes" do
      assert_equal( @emap_id, @ont.name, "OntologyTerm.name does not equal '#{@emap_id}'." )
      assert_equal( @emap_id, @ont.term, "OntologyTerm.term does not equal '#{@emap_id}'." )
      
      assert_equal( @emap_name, @ont.content, "OntologyTerm.content does not equal '#{@emap_name}'." )
      assert_equal( @emap_name, @ont.term_name, "OntologyTerm.term_name does not equal '#{@emap_name}'." )
      
      assert_equal( false, @ont.term_name.nil?, "The OntologyTerm.term_name is nil." )
      assert_equal( false, @ont.content.nil?, "The OntologyTerm.term_name is nil." )
    end
    
    should "raise appropriate errors" do
      assert_raise(OntologyTermNotFoundError) { OntologyTerm.new("FLIBBLE:5") }
    end
    
    should "respond correctly to the .parentage method" do
      assert( @ont.parentage.is_a?(Array), "OntologyTerm.parentage is not an Array when we have parents." )
      assert( @ont.parentage[0].is_a?(OntologyTerm), "OntologyTerm.parentage[0] does not return an OntologyTerm tree." )
      assert_equal( 4, @ont.parentage.size, "OntologyTerm.parentage is not returning the correct number of entries (we expect 4 for #{@emap_id})." )
    end
    
    should "be able to generate its child tree" do
      assert( @ont.child_tree.is_a?(OntologyTerm), "OntologyTerm.child_tree does not return an OntologyTerm tree." )
      assert( @ont.child_tree.root.is_a?(OntologyTerm), "OntologyTerm.child_tree.root does not return an OntologyTerm tree." )
      assert_equal( @ont.term, @ont.child_tree.root.term, "OntologyTerm.child_tree.root is equal to self." )
    end
        
    should "respond correctly to the .children method" do
      assert( @ont.children.is_a?(Array), "OntologyTerm.children is not an Array when we have children." )
      assert( @ont.children[0].is_a?(OntologyTerm), "OntologyTerm.children[0] does not return an OntologyTerm tree." )
      assert_equal( 3, @ont.children.size, "OntologyTerm.children is not returning the correct number of entries (we expect 3 direct children for #{@emap_id})." )
    end
    
    should "be able to generate a flat list of all child terms/names" do
      assert( @ont.all_child_terms.is_a?(Array), "OntologyTerm.all_child_terms is not an Array." )
      assert( @ont.all_child_terms[0].is_a?(String), "OntologyTerm.all_child_terms[0] is not an String." )
      assert_equal( 14, @ont.all_child_terms.size, "OntologyTerm.all_child_terms is not returning the correct number of entries (we expect 14 children for #{@emap_id})." )
      
      assert( @ont.all_child_names.is_a?(Array), "OntologyTerm.all_child_names is not an Array." )
      assert( @ont.all_child_names[0].is_a?(String), "OntologyTerm.all_child_names[0] is not an String." )
      assert_equal( 14, @ont.all_child_names.size, "OntologyTerm.all_child_names is not returning the correct number of entries (we expect 14 children for #{@emap_id})." )
      
      assert_equal( @ont.all_child_terms.size, @ont.all_child_names.size, "OntologyTerm.all_child_terms and OntologyTerm.all_child_names do not produce an array of the same size." )
    end
    
    should "be able to locate ontology terms via synonyms" do
      go_id = 'GO:0007242'
      ont   = OntologyTerm.new(go_id)
      
      assert_equal( 'GO:0023034', ont.term, "A synonym search for GO:0007242 has not found GO:0023034." )
      assert_equal( 'intracellular signaling pathway', ont.term_name, "A synonym search for GO:0007242 has not found 'intracellular signaling pathway'." )
    end
  end
end