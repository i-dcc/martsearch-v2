
# Error class for when we can't find a given ontology term.
class OntologyTermNotFoundError < StandardError; end

# Error class for when we get more than one ontology term found 
# for a given identifier.
class UnableToDefineOntologyTermError < StandardError; end

# Class for handling ontology terms.  Simple wrapper around the a local copy 
# of an OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
# database (created and managed by the EBI) using the Tree::TreeNode (rubytree) 
# gem as a base class.
class OntologyTerm < Tree::TreeNode
  attr_reader :term, :term_name
  
  def initialize( name, content=nil )
    super
    
    @already_fetched_parents  = false
    @already_fetched_children = false
    
    get_term_details if @content.nil? or @content.empty?
  end
  
  # Override to ensure compatibility with Tree::TreeNode.
  def term
    self.name
  end
  
  # Override to ensure compatibility with Tree::TreeNode.
  def term_name
    self.content
  end
  
  # Returns an array of the parents of this term.
  def parentage
    get_parents unless @already_fetched_parents
    @already_fetched_parents = true
    super
  end
  
  # Returns the children of this term as a tree. Will include the 
  # current term as the 'root' of the tree.
  def child_tree
    child_check
    child_tree = self.clone
    child_tree.removeFromParent!
    child_tree
  end
  
  # Returns an array of the direct children of this term.
  def children
    child_check
    super
  end
  
  # Returns a flat array containing all the possible child terms
  # for this given ontology term
  def all_child_terms
    get_all_child_lists
    return @all_child_terms
  end
  
  # Returns a flat array containing all the possible child term 
  # names for this given ontology term
  def all_child_names
    get_all_child_lists
    return @all_child_names
  end
  
  private
  
  # Helper function to query the OLS database and grab the full 
  # details of the ontology term.
  def get_term_details
    # This query ensures we look at the most recent fully loaded ontologies
    sql = <<-SQL
      select term.*
      from term
      join ontology on ontology.ontology_id = term.ontology_id
      where term.identifier = ?
      order by ontology.fully_loaded desc, ontology.load_date asc
    SQL
    
    term_set = OLS_DB[ sql, @name ].all()
    
    if term_set.size == 0
      get_term_from_synonym
    else
      subject      = term_set.first
      @content     = subject[:term_name]
      @term_pk     = subject[:term_pk]
      @ontology_id = subject[:ontology_id]
    end
  end
  
  # Helper function to try to find an ontology term via a synonym.
  def get_term_from_synonym
    sql = <<-SQL
      select term.*
      from term
      join ontology on ontology.ontology_id = term.ontology_id
      join term_synonym on term.term_pk = term_synonym.term_pk
      where term_synonym.synonym_value = ?
      order by ontology.fully_loaded desc, ontology.load_date asc
    SQL
    
    term_set = OLS_DB[ sql, @name ].all()
    
    raise OntologyTermNotFoundError, "Unable to find the term '#{@name}' in the OLS database." \
      if term_set.size == 0
    
    subject      = term_set.first
    @name        = subject[:identifier]
    @content     = subject[:term_name]
    @term_pk     = subject[:term_pk]
    @ontology_id = subject[:ontology_id]
  end
  
  # Recursive function to query the OLS database and collect all of 
  # the parent objects and insert them into @parents in the correct 
  # order.
  def get_parents( node=self )
    sql = <<-SQL
      select
        subject_term.identifier  as child_identifier,
        subject_term.term_name   as child_term,
        predicate_term.term_name as relation,
        object_term.identifier   as parent_identifier,
        object_term.term_name    as parent_term
      from
        term_relationship tr
        join term as subject_term 	on tr.subject_term_pk   = subject_term.term_pk
        join term as predicate_term on tr.predicate_term_pk = predicate_term.term_pk
        join term as object_term    on tr.object_term_pk    = object_term.term_pk
      where
            predicate_term.term_name in ('part_of','is_a','develops_from')
        and subject_term.identifier = ?
    SQL
    
    OLS_DB[ sql, node.term ].each do |row|
      parent = OntologyTerm.new( row[:parent_identifier], row[:parent_term] )
      parent << node
      get_parents( parent )
    end
  end
  
  # Recursive function to query the OLS database and collect all of 
  # the child objects and build up a tree of OntologyTerm's.
  def get_children( node=self )
    sql = <<-SQL
      select
        subject_term.identifier  as child_identifier,
        subject_term.term_name   as child_term,
        predicate_term.term_name as relation,
        object_term.identifier   as parent_identifier,
        object_term.term_name    as parent_term
      from
        term_relationship tr
        join term as subject_term   on tr.subject_term_pk   = subject_term.term_pk
        join term as predicate_term on tr.predicate_term_pk = predicate_term.term_pk
        join term as object_term    on tr.object_term_pk    = object_term.term_pk
      where
            predicate_term.term_name in ('part_of','is_a','develops_from')
        and object_term.identifier = ?
    SQL
    
    OLS_DB[sql,node.term].each do |row|
      child = OntologyTerm.new( row[:child_identifier], row[:child_term] )
      node << child
    end
  end
  
  # Helper function to check whether the children have already been 
  # found or not.
  def child_check
    if @children.nil? or @children.empty?
      get_children unless @already_fetched_children
      @already_fetched_children = true
    end
  end
  
  # Helper function to produce the flat lists of all the child
  # terms and names.
  def get_all_child_lists
    child_check
    
    if @all_child_terms.nil? and @all_child_names.nil?
      @all_child_terms = []
      @all_child_names = []
      
      self.children.each do |child|
        @all_child_terms.push( child.term )
        @all_child_terms.push( child.all_child_terms )
        @all_child_names.push( child.term_name )
        @all_child_names.push( child.all_child_names )
      end
      
      @all_child_terms = @all_child_terms.flatten.uniq
      @all_child_names = @all_child_names.flatten.uniq
    end
  end
end
