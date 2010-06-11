
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
    @name, @content = name, content
    
    @already_fetched_parents  = false
    @already_fetched_children = false
    
    super
    
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
    get_children unless @already_fetched_children
    @already_fetched_children = true
    
    child_tree = self.clone
    child_tree.removeFromParent!
    child_tree
  end
  
  # Returns an array of the direct children of this term.
  def children
    if @children.nil? or @children.empty?
      get_children unless @already_fetched_children
      @already_fetched_children = true
    end
    super
  end
  
  private
  
  # Helper function to query the OLS database and grab the full 
  # details of the ontology term.
  def get_term_details
    term_set = OLS_DB[:term].filter(:identifier => @name)
    
    raise UnableToDefineOntologyTermError, "More than one ontology term has been found for '#{self.term}'." \
      if term_set.count() > 1
    
    raise OntologyTermNotFoundError, "Unable to find the term '#{@name}' in the OLS database." \
      if term_set.count() == 0
    
    subject = term_set.first
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
      get_children( child )
    end
  end
  
end
