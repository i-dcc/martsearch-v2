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

my $image_cache = get_test_images();
my $pheno_data  = query_biomart(
  $HTTP_AGENT,
  {
    url        => $CONF->{"url"} . "/martservice",
    dataset    => $CONF->{"dataset_name"},
    filters    => $CONF->{"searching"}->{"filters"},
    attributes => $CONF->{"searching"}->{"attributes"}
  }
);

generate_spreadsheet( "$SCRIPT_DIR/../../../public/pheno_overview.xls", $pheno_data, $image_cache );

##
## Subroutines
##

# Function to print out our phenotyping spreadsheet given a biomart 
# data return.
sub generate_spreadsheet {
  my ( $filename, $data, $colonies_with_details ) = @_;
  
  # Use this variable to set the number of columns of data we have 
  # per-row before we print out the test results...
  my $number_of_leading_text_entries = 5;
  
  ##
  ## Set up the spreadsheet and apply some formatting...
  ##
  
  my $workbook     = Spreadsheet::WriteExcel->new( $filename );
  my $worksheet    = $workbook->add_worksheet('Phenotyping Overview');
  
  # Cell formatting...
  
  my $general_format    = $workbook->add_format( bg_color => 'white', border => 1, border_color => 'gray' );
  my $test_formats      = _xls_setup_result_formats( $workbook, { border => 1, border_color => 'gray', bold => 1, align => 'center', valign => 'vcenter' } );
  my $title_format      = $workbook->add_format( bold => 1, size => 10, bg_color => 'white', border => 1, border_color => 'gray' );
  my $test_title_format = $workbook->add_format( bold => 1, size => 10, bg_color => 'white', align => 'center', border => 1, border_color => 'gray' ); $test_title_format->set_rotation(90);
  
  # Column width formatting...
  my %alpha_nums;
  my $number = 1;
  foreach ('A'..'Z') { $alpha_nums{$number} = $_; $number++; }
  $worksheet->set_column( 'A:'.$alpha_nums{$number_of_leading_text_entries}, 20 );
  $worksheet->set_column( $alpha_nums{$number_of_leading_text_entries+1}.':IV', 3 );
  
  # Row height formatting...
  for (my $n = 1; $n < scalar( @{$data->{data}} )+1; $n++) {
    $worksheet->set_row( $n, 15 );
  }
  
  # Freeze panes...
  $worksheet->freeze_panes(1, 0);
  
  ##
  ## Print the header...
  ##
  
  my $colony_prefix_pos = undef;
  my $i = 0;
  
  foreach my $header ( @{ $data->{headers} } ) {
    if ( $i < $number_of_leading_text_entries ) {
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

  ##
  ## Now print the data...
  ##
  
  my $number_of_columns = 0;
  
  for ( my $row = 0 ; $row < scalar( @{ $data->{data} } ) ; $row++ ) {

    # First process the line into plain text and test info buckets
    my @processed_data;
    for ( my $col = 0 ; $col < scalar( @{ $data->{data}->[$row] } ) ; $col++ ) {
      if ( $col < $number_of_leading_text_entries ) {
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
    
    $number_of_columns = scalar(@processed_data);

    # Now write the processed data
    for ( my $col = 0 ; $col < scalar(@processed_data) ; $col++ ) {
      if ( $col < $number_of_leading_text_entries ) {
        # plain text
        $worksheet->write( $row + 1, $col, $processed_data[$col], $general_format );
      }
      else {
        # test info
        my $result = $processed_data[$col];

        # write the comments if we have any
        if ( defined $result->{comment} && !( $result->{comment} =~ /^$/ ) ) {
          $worksheet->write_comment( $row + 1, $col, $result->{comment} );
        }
        
        # see if we have a test details page to link to...
        my $colony_prefix = $processed_data[$colony_prefix_pos];
        my $pheno_details_url = "http://www.sanger.ac.uk/mouseportal/phenotyping/$colony_prefix/" . $result->{test_name} . "/";
        
        if ( defined $colonies_with_details->{$colony_prefix}->{ $result->{test_name} } and $colonies_with_details->{$colony_prefix}->{ $result->{test_name} } ) {
          # if we do, write a link to it...
          $worksheet->write_url( $row + 1, $col, $pheno_details_url, ">", _xls_test_result_format( $test_formats, $result->{value} ) );
        }
        else {
          # just write the plain results cell...
          $worksheet->write( $row + 1, $col, "", _xls_test_result_format( $test_formats, $result->{value} ) );
        }
      }
    }
  }
  
  ##
  ## Finally, print the legend...
  ##
  
  $worksheet->write( 2, $number_of_columns+2, "LEGEND" );
  $worksheet->write( 4, $number_of_columns+3, "test complete and data/resources available" );
  $worksheet->write( 4, $number_of_columns+2, "", $test_formats->{completed_data_available} );
  $worksheet->write( 5, $number_of_columns+3, "test considered interesting" );
  $worksheet->write( 5, $number_of_columns+2, "", $test_formats->{significant_difference} );
  $worksheet->write( 6, $number_of_columns+3, "early indication of possible phenotype" );
  $worksheet->write( 6, $number_of_columns+2, "", $test_formats->{early_indication} );
  $worksheet->write( 7, $number_of_columns+3, "test done but not considered interesting" );
  $worksheet->write( 7, $number_of_columns+2, "", $test_formats->{no_significant_difference} );
  $worksheet->write( 8, $number_of_columns+3, "test not applicable, e.g. no LacZ, therefore expression not possible" );
  $worksheet->write( 8, $number_of_columns+2, "", $test_formats->{not_applicable} );
  $worksheet->write( 9, $number_of_columns+3, "test not carried out" );
  $worksheet->write( 9, $number_of_columns+2, "", $test_formats->{test_not_done} );
  $worksheet->write( 10, $number_of_columns+3, "link to a phenotyping test report page" );
  $worksheet->write( 10, $number_of_columns+2, ">", $test_formats->{test_not_done} );
  
}

# Helper function to set-up all of the formatting options for the
# different test results possible.
sub _xls_setup_result_formats {
  my ( $workbook, $default_props ) = @_;

  my $xls_formats = {
    test_not_done             => 'white',
    completed_data_available  => 'navy',
    significant_difference    => 'red',
    no_significant_difference => 44, # light blue
    not_applicable            => 'silver',
    early_indication          => 'yellow'
  };
  
  foreach my $result ( keys %{$xls_formats} ) {
    my $format = $workbook->add_format( %{$default_props} );
    $format->set_bg_color( $xls_formats->{$result} );
    $xls_formats->{$result} = $format;
  }
  
  return $xls_formats;
}

# Helper function to choose which cell format should be used for a 
# given phenotyping test result.
sub _xls_test_result_format {
  my ( $tf, $result ) = @_;
  my $form;
  
  if    ( $result =~ /Done but not considered interesting/i ) { $form = $tf->{no_significant_difference}; }
  elsif ( $result =~ /Considered interesting/i )              { $form = $tf->{significant_difference}; }
  elsif ( $result =~ /Not applicable/i )                      { $form = $tf->{not_applicable}; }
  elsif ( $result =~ /Early indication/i )                    { $form = $tf->{early_indication}; }
  elsif ( $result =~ /Complete and data/i )                   { $form = $tf->{completed_data_available}; }
  else                                                        { $form = $tf->{test_not_done}; }
  
  return $form;
}

# Helper function to run the rake task 'phenotyping:image_cache_json' 
# to generate, a JSON dump of all of the phenotyping images stored on 
# disk and read it in.
sub get_test_images {
  my $SCRIPT_DIR = dirname(__FILE__);
  
  system("rake --rakefile $SCRIPT_DIR/../../../Rakefile phenotyping:image_cache_json > /dev/null");
  my $image_cache = "";
  open( IMAGEJSON, "$SCRIPT_DIR/sanger-phenotyping-pheno_links.json" );
  while (<IMAGEJSON>) { $image_cache .= $_; }
  close(IMAGEJSON);
  system("rm $SCRIPT_DIR/sanger-phenotyping-pheno_links.json");

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

  return { headers => \@headers, data => \@array_of_arrays };
}
