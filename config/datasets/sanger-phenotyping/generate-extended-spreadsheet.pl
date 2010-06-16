#! /usr/bin/perl

#
# This is a one-off script (not strictly part of the portal) to 
# generate a spreadsheet of all the phenotyping data but break 
# it down into the individual test parameters so that cluster 
# analysis can be done on the data.
#

use strict;
use warnings FATAL => "all";
use File::Basename;
use LWP;
use JSON;
use XML::Writer;
use Spreadsheet::WriteExcel;
use Data::Dumper;

##
## Read in the configuration and create an LWP agent
##

my $SCRIPT_DIR = dirname(__FILE__);

my $config_string = "";
open( CONFIG, "$SCRIPT_DIR/config.json" );
while (<CONFIG>) { $config_string .= $_; }
close(CONFIG);

my $test_conf_string = "";
open( CONFIG, "$SCRIPT_DIR/test_conf.json" );
while (<CONFIG>) { $test_conf_string .= $_; }
close(CONFIG);

my $CONF       = JSON->new->decode($config_string) or die "Unable to read phenotyping config.json";
my $TEST_CONF  = JSON->new->decode($test_conf_string) or die "Unable to read phenotyping test_conf.json";
my $HTTP_AGENT = LWP::UserAgent->new();

##
## Process the test_conf to generate a list of tests and parameters and 
## read in the image data...
##

my $test_conf   = {};
my $test_map    = {};
my $image_map   = {};
my $image_cache = get_test_images();

foreach my $project ( keys %{$TEST_CONF} ) {
  foreach my $test ( keys %{$TEST_CONF->{$project}} ) {
    $test_map->{$test} = $TEST_CONF->{$project}->{$test}->{name};
    my $params         = $TEST_CONF->{$project}->{$test}->{images};

    unless ( defined $test_conf->{$test} ) { $test_conf->{$test} = {}; }

    foreach my $param ( @{$params} ) {
      foreach my $key ( keys %{$param} ) {
        $test_conf->{$test}->{$param->{$key}}++;
        $image_map->{$test}->{$key} = $param->{$key};
      }
    }
  }
}

##
## Fetch the list of colonies, genes, comparisons from the mart
##

my $subjects  = query_biomart(
  $HTTP_AGENT,
  {
    url        => $CONF->{"url"} . "/martservice",
    dataset    => $CONF->{"dataset_name"},
    filters    => {},
    attributes => $CONF->{"searching"}->{"attributes"}
  }
);

my @colonies = ();
my $attr_positions = {};

for (my $i = 0; $i < scalar(@{$subjects->{headers}}) ; $i++) {
  my $attr = $CONF->{"searching"}->{"attributes"}->[$i];
  $attr =~ s/\_/\-/g;
  $attr_positions->{$attr} = $i;
}

#print Dumper($attr_positions);
#print "\n\n---\n\n";
#print Dumper($subjects->{data}->[0]);

foreach my $data_row ( @{$subjects->{data}} ) {
  if ( $data_row->[ $attr_positions->{'pipeline'} ] eq "Sanger MGP" ) {
    push @colonies, $data_row;
  }
}

##
## Set up the spreadsheet
##

my $filename  = "extended-heatmap.xls";
my $workbook  = Spreadsheet::WriteExcel->new( $filename ); $workbook->compatibility_mode();
my $worksheet = $workbook->add_worksheet('Extended Heatmap');
my $no_of_leading_entries = 2;

_xls_setup_worksheet( $worksheet, $no_of_leading_entries, scalar(@colonies)+1, 500 );

# Cell formatting...

my $formats = {
  title         => $workbook->add_format( size => 10 ),
  subject_title => $workbook->add_format( size => 10, align => 'center', rotation => 90 )
};

# Header

$worksheet->write( 0, $no_of_leading_entries-1, 'Comparison', $formats->{title} );
$worksheet->write( 1, $no_of_leading_entries-1, 'Colony Prefix', $formats->{title} );
$worksheet->write( 2, $no_of_leading_entries-1, 'Marker Symbol', $formats->{title} );

my $col = 0;
foreach my $subject ( @colonies ) {
  $worksheet->write( 0, $col+$no_of_leading_entries, $subject->[$attr_positions->{'comparison'}], $formats->{subject_title} );
  $worksheet->write( 1, $col+$no_of_leading_entries, $subject->[$attr_positions->{'colony-prefix'}], $formats->{subject_title} );
  $worksheet->write( 2, $col+$no_of_leading_entries, $subject->[$attr_positions->{'marker-symbol'}], $formats->{subject_title} );
  $col++;
}

# Data

my $row = 3;
foreach my $test ( sort keys %{$test_conf} ) {
  if ( scalar(keys %{$test_conf->{$test}}) == 0 ) {
    $worksheet->write( $row, 0, $test_map->{$test}, $formats->{title} );
    $row++;
    next;
  }
  
  foreach my $param ( sort keys %{$test_conf->{$test}} ) {
    $worksheet->write( $row, 0, $test_map->{$test}, $formats->{title} );
    $worksheet->write( $row, 1, $param, $formats->{title} );
    
    my $col = 0;
    foreach my $subject ( @colonies ) {
      my $colony = $subject->[$attr_positions->{'colony-prefix'}];
      my $have_i_got_an_image = 0;
      
      # See if we have an image...
      foreach my $found_image ( @{$image_cache->{$colony}->{$test}} ) {
        unless ( defined $image_map->{$test}->{$found_image} ) {
          warn "WTF - found '$found_image' for '$test'...\n";
          next;
        }
        
        if ( $image_map->{$test}->{$found_image} eq $param ) {
          $have_i_got_an_image = 1;
        }
      }
      
      # Now compare this against the reported heatmap value...
      my $heatmap_result = $subject->[$attr_positions->{$test}];
      
      # Print an entry if we have data worth a damn...
      if ( $heatmap_result eq 'Done but not considered interesting.' ) {
        $worksheet->write( $row, $col+$no_of_leading_entries, '0', undef );
      }
      elsif ( $heatmap_result eq 'Considered interesting.' ) {
        if ( $have_i_got_an_image == 1 ) {
          $worksheet->write( $row, $col+$no_of_leading_entries, '1', undef );
        }
        else {
          $worksheet->write( $row, $col+$no_of_leading_entries, '0', undef );
        }
      }
      
      $col++;
    }
    
    $row++;
  }
}

# Helper function to setup a worksheet for the heatmap, i.e. set
# the row/column height/width parameters, and freeze panes.
sub _xls_setup_worksheet {
  my ( $worksheet, $no_of_leading_text_entries, $no_of_cols, $no_of_rows ) = @_;
  
  # Column width formatting...
  $worksheet->set_column( 0, $no_of_leading_text_entries-1, 35.5 );
  $worksheet->set_column( $no_of_leading_text_entries, $no_of_cols, 3 );
  
  # Row height formatting...
  for (my $n = 3; $n < $no_of_rows+1; $n++) { $worksheet->set_row( $n, 15 ); }

  # Freeze panes...
  $worksheet->freeze_panes(3, 2);
}

# Helper function to run the rake task 'phenotyping:image_cache_json' 
# to generate, a JSON dump of all of the phenotyping images stored on 
# disk and read it in.
sub get_test_images {
  my $SCRIPT_DIR = dirname(__FILE__);
  
  system("rake --rakefile $SCRIPT_DIR/../../../Rakefile phenotyping:image_cache_json > /dev/null");
  my $image_cache = "";
  open( IMAGEJSON, "/tmp/sanger-phenotyping-test_images.json" );
  while (<IMAGEJSON>) { $image_cache .= $_; }
  close(IMAGEJSON);
  #system("rm /tmp/sanger-phenotyping-test_images.json");

  $image_cache = JSON->new->decode($image_cache) 
    or die "Unable to read/find file sanger-phenotyping-test_images.json";
  
  # Now move through the colonies and convert the arrays of test 
  # names to hashes for easy lookup later...
  my $processed_image_cache = {};
  foreach my $colony ( keys %{ $image_cache } ) {
    foreach my $test ( keys %{ $image_cache->{$colony} } ) {
      unless ( defined $processed_image_cache->{$colony}->{$test} ) {
        $processed_image_cache->{$colony}->{$test} = [];
      }
      
      foreach my $image ( keys %{ $image_cache->{$colony}->{$test} } ) {
        push @{$processed_image_cache->{$colony}->{$test}}, $image;
      }
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
