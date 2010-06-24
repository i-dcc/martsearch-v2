#! /usr/bin/perl

use strict;
use warnings FATAL => "all";
use File::Basename;
use LWP;
use JSON;
use XML::Writer;
use Spreadsheet::WriteExcel;

##
## Read in the configuration and create an LWP Agent
##

my $SCRIPT_DIR = dirname(__FILE__);

my $config_string = "";
open( CONFIG, "$SCRIPT_DIR/config.json" );
while (<CONFIG>) { $config_string .= $_; }
close(CONFIG);

my $CONF       = JSON->new->decode($config_string) or die "Unable to read phenotyping config.json";
my $HTTP_AGENT = LWP::UserAgent->new();

##
## Get on with it...
##

my $pheno_links = get_pheno_links();
my $pheno_data  = query_biomart(
  $HTTP_AGENT,
  {
    url        => $CONF->{"url"} . "/martservice",
    dataset    => $CONF->{"dataset_name"},
    filters    => $CONF->{"searching"}->{"filters"},
    attributes => $CONF->{"searching"}->{"attributes"}
  }
);

generate_spreadsheet( "/software/team87/brave_new_world/data/generated/pheno_overview.xls", $pheno_data, $pheno_links );

##
## Subroutines
##

# Function to print out our phenotyping spreadsheet given a biomart 
# data return.
sub generate_spreadsheet {
  my ( $filename, $data, $colonies_with_details ) = @_;
  
  # Use this variable to set the number of columns of data we have 
  # per-row before we print out the test results...
  my $no_of_leading_text_entries = 5;
  
  ##
  ## Set up the spreadsheet and apply some formatting...
  ##
  
  my $workbook = Spreadsheet::WriteExcel->new( $filename );
  
  # Cell formatting...
  
  my $formats = {
    general        => $workbook->add_format( bg_color => 'white', border => 1, border_color => 'gray' ),
    unlinked_tests => _xls_setup_result_formats( $workbook, { border => 1, border_color => 'gray', align => 'center', valign => 'vcenter' } ),
    linked_tests   => _xls_setup_result_formats( $workbook, { border => 1, border_color => 'gray', align => 'center', valign => 'vcenter', bold => 1, underline => 1 } ),
    title          => $workbook->add_format( bold => 1, size => 10, bg_color => 'white', border => 1, border_color => 'gray' ),
    test_title     => $workbook->add_format( bold => 1, size => 10, bg_color => 'white', align => 'center', border => 1, border_color => 'gray', rotation => 90 )
  };
  
  ##
  ## Add our worksheets and set them up
  ##
  
  my $unsorted_worksheet = $workbook->add_worksheet('Overview');
  #my $sorted_worksheet   = $workbook->add_worksheet('Overview (Sortable)');
  
  _xls_setup_worksheet( $unsorted_worksheet, $no_of_leading_text_entries, scalar( @{$data->{data}} ) );
  #_xls_setup_worksheet( $sorted_worksheet, $no_of_leading_text_entries, scalar( @{$data->{data}} ) );
  
  _xls_print_headers( $unsorted_worksheet, $data->{headers}, $no_of_leading_text_entries, $formats );
  #_xls_print_headers( $sorted_worksheet, $data->{headers}, $no_of_leading_text_entries, $formats );

  ##
  ## Now print the data and legends...
  ##
  
  my $number_of_columns = write_data( $unsorted_worksheet, $data, $colonies_with_details, $no_of_leading_text_entries, $formats );
  #write_data( $sorted_worksheet, $data, $colonies_with_details, $no_of_leading_text_entries, $formats );
  
  write_unsorted_legend( $unsorted_worksheet, $number_of_columns, $formats );
  #write_sorted_legend( $sorted_worksheet, $number_of_columns, $formats );
  
}

# Helper function to setup a worksheet for the heatmap, i.e. set
# the row/column height/width parameters, and freeze panes.
sub _xls_setup_worksheet {
  my ( $worksheet, $no_of_leading_text_entries, $no_of_rows ) = @_;
  
  # Column width formatting...
  my %alpha_nums;
  my $number = 1;
  foreach ('A'..'Z') { $alpha_nums{$number} = $_; $number++; }
  $worksheet->set_column( 'A:'.$alpha_nums{$no_of_leading_text_entries}, 20 );
  $worksheet->set_column( $alpha_nums{$no_of_leading_text_entries+1}.':IV', 3 );
  
  # Row height formatting...
  for (my $n = 1; $n < $no_of_rows+1; $n++) { $worksheet->set_row( $n, 15 ); }

  # Freeze panes...
  $worksheet->freeze_panes(1, 0);
}

# Helper function to print the header row for a heatmap worksheet.
sub _xls_print_headers {
  my ( $worksheet, $header_data, $no_of_leading_text_entries, $formats ) = @_;
  
  my $title_format      = $formats->{title};
  my $test_title_format = $formats->{test_title};
  my $colony_prefix_pos = undef;
  my $i = 0;
  
  foreach my $header ( @{ $header_data } ) {
    if ( $i < $no_of_leading_text_entries ) {
      if ( $header =~ /Colony Prefix/i ) { $colony_prefix_pos = $i; }
      $worksheet->write( 0, $i, $header, $title_format );
      $i++;
    }
    elsif ( $header =~ /Comment/ ) {
      next;
    }
    else {
      $worksheet->write( 0, $i, $header, $test_title_format );
      $i++;
    }
  }
}

# Helper function to set-up all of the formatting options for the
# different test results possible.
sub _xls_setup_result_formats {
  my ( $workbook, $default_props ) = @_;

  my $xls_formats = {
    completed_data_available  => { bg => 'navy', col => 'white' },
    significant_difference    => { bg => 'red' },
    no_significant_difference => { bg => 44 }, # light blue
    early_indication          => { bg => 'yellow' },
    not_applicable            => { bg => 'silver' },
    test_pending              => { bg => 'white' }
  };
  
  foreach my $result ( keys %{$xls_formats} ) {
    my $format = $workbook->add_format( %{$default_props} );
    if ( defined $xls_formats->{$result}->{bg} ) {
      $format->set_bg_color( $xls_formats->{$result}->{bg} );
    }
    if ( defined $xls_formats->{$result}->{col} ) {
      $format->set_color( $xls_formats->{$result}->{col} );
    }
    
    $xls_formats->{$result} = $format;
  }
  
  return $xls_formats;
}

sub _xls_setup_test_result_code {
  my $test_mapping = {
    completed_data_available  => 1,
    significant_difference    => 2,
    no_significant_difference => 3,
    early_indication          => 4,
    not_applicable            => 5,
    test_pending              => 6
  };
  return $test_mapping;
}

# Helper function to choose which cell format should be used for a 
# given phenotyping test result.
sub _xls_test_result_format {
  my ( $tf, $result ) = @_;
  my $form;
  
  if    ( $result eq "Test complete and data\/resources available" )  { $form = $tf->{completed_data_available}; }
  elsif ( $result eq "Test complete and considered interesting" )     { $form = $tf->{significant_difference}; }
  elsif ( $result eq "Test complete but not considered interesting" ) { $form = $tf->{no_significant_difference}; }
  elsif ( $result eq "Early indication of possible phenotype" )       { $form = $tf->{early_indication}; }
  elsif ( $result =~ /^Test not performed or applicable/i )           { $form = $tf->{not_applicable}; }
  elsif ( $result eq "Test abandoned" )                               { $form = $tf->{test_abandoned}; }
  else                                                                { $form = $tf->{test_pending}; }
  
  return $form;
}

# Helper function to sort the data row into buckets of title text 
# and results data.
sub prepare_data_for_writing {
  my ( $data, $row, $no_of_leading_text_entries ) = @_;
  
  my @processed_data;
  
  for ( my $col = 0 ; $col < scalar( @{ $data->{data}->[$row] } ) ; $col++ ) {
    if ( $col < $no_of_leading_text_entries ) {
      push( @processed_data, $data->{data}->[$row]->[$col] );
    }
    else {
      my $test_name = $data->{attributes}->[$col];
      $test_name =~ s/\_/\-/g;
      
      push(
        @processed_data,
        {
          value     => $data->{data}->[$row]->[$col],
          comment   => $data->{data}->[$row]->[$col + 1],
          test_name => $test_name
        }
      );
      $col++;
    }
  }
  
  return \@processed_data;
}

# Helper function to write the data onto a worksheet.
sub write_data {
  my ( $worksheet, $data, $colonies_with_details, $no_of_leading_text_entries, $formats ) = @_;
  
  my $number_of_columns = undef;
  my $colony_prefix_pos = undef;

  for (my $i = 0; $i < scalar( @{$data->{headers}} ); $i++) {
    my $header = $data->{headers}->[$i];
    if ( $header =~ /Colony Prefix/i ) { $colony_prefix_pos = $i; }
  }
  
  for ( my $row = 0 ; $row < scalar( @{ $data->{data} } ) ; $row++ ) {

    # First process the line into plain text and test info buckets
    my $processed_data_ref = prepare_data_for_writing( $data, $row, $no_of_leading_text_entries );
    my @processed_data     = @{$processed_data_ref};
    $number_of_columns     = scalar(@processed_data);

    # Now write the processed data
    for ( my $col = 0 ; $col < scalar(@processed_data) ; $col++ ) {
      if ( $col < $no_of_leading_text_entries ) {
        # plain text
        $worksheet->write( $row + 1, $col, $processed_data[$col], $formats->{general} );
      }
      else {
        # test info
        if ( $worksheet->get_name() =~ /Sort/ ) {
          write_sorted_results( $worksheet, $row, $col, \@processed_data, $colony_prefix_pos, $colonies_with_details, $formats );
        } else {
          write_unsorted_results( $worksheet, $row, $col, \@processed_data, $colony_prefix_pos, $colonies_with_details, $formats );
        }
      }
    }
  }
  
  return $number_of_columns;
}

# Helper function to write the data cells for the unsortable heatmap.
sub write_unsorted_results {
  my ( $worksheet, $row, $col, $processed_data, $colony_prefix_pos, $colonies_with_details, $formats ) = @_;
  
  my $result = $processed_data->[$col];
  
  # write the comments if we have any
  if ( defined $result->{comment} && !( $result->{comment} =~ /^$/ ) ) {
    $worksheet->write_comment( $row + 1, $col, $result->{comment} );
  }
  
  # see if we have a test details page to link to...
  my $colony_prefix     = $processed_data->[$colony_prefix_pos];
  my $pheno_details_url = "http://www.sanger.ac.uk/mouseportal/phenotyping/$colony_prefix/" . $result->{test_name} . "/";
  
  if ( defined $colonies_with_details->{$colony_prefix}->{ $result->{test_name} } and $colonies_with_details->{$colony_prefix}->{ $result->{test_name} } ) {
    # if we do, write a link to it...
    $worksheet->write_url( $row + 1, $col, $pheno_details_url, ">", _xls_test_result_format( $formats->{linked_tests}, $result->{value} ) );
  }
  else {
    # just write the plain results cell...
    $worksheet->write( $row + 1, $col, "", _xls_test_result_format( $formats->{unlinked_tests}, $result->{value} ) );
  }
  
}

# Helper function to write the data cells for the sortable heatmap.
sub write_sorted_results {
  my ( $worksheet, $row, $col, $processed_data, $colony_prefix_pos, $colonies_with_details, $formats ) = @_;
  
  my $result    = $processed_data->[$col];
  my $test_code = _xls_setup_test_result_code();
  
  # write the comments if we have any
  if ( defined $result->{comment} && !( $result->{comment} =~ /^$/ ) ) {
    $worksheet->write_comment( $row + 1, $col, $result->{comment} );
  }
  
  # see if we have a test details page to link to...
  my $colony_prefix     = $processed_data->[$colony_prefix_pos];
  my $pheno_details_url = "http://www.sanger.ac.uk/mouseportal/phenotyping/$colony_prefix/" . $result->{test_name} . "/";
  
  if ( defined $colonies_with_details->{$colony_prefix}->{ $result->{test_name} } and $colonies_with_details->{$colony_prefix}->{ $result->{test_name} } ) {
    # if we do, write a link to it...
    $worksheet->write_url( $row + 1, $col, $pheno_details_url, _xls_test_result_format( $test_code, $result->{value} ), _xls_test_result_format( $formats->{linked_tests}, $result->{value} ) );
  }
  else {
    # just write the plain results cell...
    $worksheet->write( $row + 1, $col, _xls_test_result_format( $test_code, $result->{value} ), _xls_test_result_format( $formats->{unlinked_tests}, $result->{value} ) );
  }
  
}

# Helper function to write the legend for the unsortable heatmap.
sub write_unsorted_legend {
  my ( $worksheet, $number_of_columns, $formats ) = @_;
  
  my $unlinked_formats = $formats->{unlinked_tests};
  my $linked_formats   = $formats->{linked_tests};
  
  $worksheet->write( 2, $number_of_columns+2, "LEGEND" );
  $worksheet->write( 4, $number_of_columns+3, "Test complete and data/resources available" );
  $worksheet->write( 4, $number_of_columns+2, "", $unlinked_formats->{completed_data_available} );
  $worksheet->write( 5, $number_of_columns+3, "Test complete and considered interesting" );
  $worksheet->write( 5, $number_of_columns+2, "", $unlinked_formats->{significant_difference} );
  $worksheet->write( 6, $number_of_columns+3, "Test complete but not considered interesting" );
  $worksheet->write( 6, $number_of_columns+2, "", $unlinked_formats->{no_significant_difference} );
  $worksheet->write( 7, $number_of_columns+3, "Early indication of possible phenotype" );
  $worksheet->write( 7, $number_of_columns+2, "", $unlinked_formats->{early_indication} );
  $worksheet->write( 8, $number_of_columns+3, "Test not performed or applicable e.g. no lacZ reporter therefore no expression" );
  $worksheet->write( 8, $number_of_columns+2, "", $unlinked_formats->{not_applicable} );
  $worksheet->write( 9, $number_of_columns+3, "Test pending" );
  $worksheet->write( 9, $number_of_columns+2, "", $unlinked_formats->{test_pending} );
  $worksheet->write( 10, $number_of_columns+3, "Link to a phenotyping test report page" );
  $worksheet->write( 10, $number_of_columns+2, ">", $linked_formats->{test_pending} );
}

# Helper function to write the cells for the sortable heatmap.
sub write_sorted_legend {
  my ( $worksheet, $number_of_columns, $formats ) = @_;
  
  my $test_formats   = $formats->{unlinked_tests};
  my $linked_formats = $formats->{linked_tests};
  my $test_code      = _xls_setup_test_result_code();
  
  $worksheet->write( 2, $number_of_columns+2, "LEGEND" );
  $worksheet->write( 4, $number_of_columns+3, "Test complete and data/resources available" );
  $worksheet->write( 4, $number_of_columns+2, $test_code->{completed_data_available}, $test_formats->{completed_data_available} );
  $worksheet->write( 5, $number_of_columns+3, "Test complete and considered interesting" );
  $worksheet->write( 5, $number_of_columns+2, $test_code->{significant_difference}, $test_formats->{significant_difference} );
  $worksheet->write( 6, $number_of_columns+3, "Test complete but not considered interesting" );
  $worksheet->write( 6, $number_of_columns+2, $test_code->{no_significant_difference}, $test_formats->{no_significant_difference} );
  $worksheet->write( 7, $number_of_columns+3, "Early indication of possible phenotype" );
  $worksheet->write( 7, $number_of_columns+2, $test_code->{early_indication}, $test_formats->{early_indication} );
  $worksheet->write( 8, $number_of_columns+3, "Test not performed or applicable e.g. no lacZ reporter therefore no expression" );
  $worksheet->write( 8, $number_of_columns+2, $test_code->{not_applicable}, $test_formats->{not_applicable} );
  $worksheet->write( 9, $number_of_columns+3, "Test pending" );
  $worksheet->write( 9, $number_of_columns+2, $test_code->{test_pending}, $test_formats->{test_pending} );
  $worksheet->write( 10, $number_of_columns+3, "Link to a phenotyping test report page" );
  $worksheet->write( 10, $number_of_columns+2, "x", $linked_formats->{test_pending} );
  
}

# Helper function to run the rake task 'phenotyping:pheno_link_json' 
# to generate, a JSON dump of all of the phenotyping tests that should 
# have a details page on the portal
sub get_pheno_links {
  my $SCRIPT_DIR = dirname(__FILE__);
  
  system("rake --rakefile $SCRIPT_DIR/../../../Rakefile phenotyping:pheno_link_json > /dev/null");
  my $image_cache = "";
  open( IMAGEJSON, "/tmp/sanger-phenotyping-pheno_links.json" );
  while (<IMAGEJSON>) { $image_cache .= $_; }
  close(IMAGEJSON);
  system("rm /tmp/sanger-phenotyping-pheno_links.json");

  $image_cache = JSON->new->decode($image_cache) 
    or die "Unable to read/find file sanger-phenotyping-pheno_links.json";
  
  # Now move through the colonies and convert the arrays of test 
  # names to hashes for easy lookup later...
  my $processed_image_cache = {};
  foreach my $colony ( keys %{ $image_cache } ) {
    foreach my $test ( @{ $image_cache->{$colony} } ) {
      $processed_image_cache->{$colony}->{$test} = 1;
    }
  }
  
  return $processed_image_cache;
}

# Generic helper function to submit a query to a biomart and
# return the processed results.
sub query_biomart {
  my ( $agent, $params ) = @_;

  # Process the filters
  my $filters = [];
  foreach my $name ( keys %{ $params->{filters} } ) {
    push( @{$filters}, { name => $name, value => $params->{filters}->{$name} } );
  }

  # Now compose our XML
  my $xml = biomart_xml( $params->{dataset}, $filters, $params->{attributes} );

  # POST it to biomart
  my $response = $HTTP_AGENT->post( $params->{url}, { query => $xml } );

  # Process the response
  if ( $response->is_success ) {
    my $results = process_biomart_results( $response->content() );
    $results->{attributes} = $params->{attributes};
    return $results;
  }
  else {
    die "Biomart (" . $params->{dataset} . ") server error $!";
  }
}

# Helper function to generate the XML for the biomart query.
sub biomart_xml {
  my ( $mart, $filters, $attributes ) = @_;

  my $xml_text;
  my $xml = new XML::Writer( OUTPUT => \$xml_text );

  $xml->xmlDecl("UTF-8");
  $xml->doctype("Query");

  $xml->startTag(
    "Query",
    "virtualSchemaName"    => "default",
    "formatter"            => "TSV",
    "header"               => "1",
    "uniqueRows"           => "1",
    "count"                => "",
    "datasetConfigVersion" => "0.6"
  );

  $xml->startTag(
    "Dataset",
    "name"      => $mart,
    "interface" => "default"
  );

  foreach my $filter ( @{$filters} ) {
    $xml->emptyTag( "Filter", "name" => $filter->{name}, "value" => $filter->{value} );
  }

  foreach my $attribute ( @{$attributes} ) {
    $xml->emptyTag( "Attribute", "name" => $attribute );
  }

  $xml->endTag("Dataset");
  $xml->endTag("Query");

  $xml->end();

  return $xml_text;
}

# Helper function to convert a returned biomart (TSV) resultset
# into an array of arrays for further processing.
sub process_biomart_results {
  my ( $tsv ) = @_;

  my @array_of_arrays;

  # Split the tsv string on newlines, then each line on tabs
  # before building into the JSON output
  my @data_by_line = split( "\n", $tsv );

  # Remove the headers
  my $header_line = shift(@data_by_line);
  my @headers = split( "\t", $header_line );

  for ( my $i = 0 ; $i < scalar(@data_by_line) ; $i++ ) {
    my @data_row = split( "\t", $data_by_line[$i] );
    push( @array_of_arrays, \@data_row );
  }

  # Sort the results on 'Marker Symbol' and 'Comparison' columns
  my( $marker_symbol_idx ) = grep { $headers[$_] eq 'Marker Symbol' } 0..$#headers;
  my( $comparison_idx )    = grep { $headers[$_] eq 'Comparison' }    0..$#headers;
  
  @array_of_arrays = sort {
      $a->[$marker_symbol_idx] cmp $b->[$marker_symbol_idx]
      or $a->[$comparison_idx] cmp $b->[$comparison_idx]
  } @array_of_arrays;

  return { headers => \@headers, data => \@array_of_arrays };
}
