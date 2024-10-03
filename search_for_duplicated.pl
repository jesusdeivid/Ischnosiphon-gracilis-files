#!/usr/bin/perl
use strict;
use warnings;

# Define the directory where the .tsv and .gff files are located
my $busco_dir = "./busco_tsv";  # Adjust to your path
my $gff_dir = "./gff_files";    # Adjust to your path

# A hash to store duplicated genes by sample
my %duplicated_genes;

# Function to process BUSCO .tsv files
sub process_busco_tsv {
    my ($file) = @_;
    open(my $fh, "<", $file) or die "Could not open file $file: $!";

    while (<$fh>) {
        chomp;
        my @columns = split("\t");
        my $busco_id = $columns[0];
        my $status = $columns[1];
        my $sequence = $columns[2];

        # If the status is "Duplicated", add to the hash
        if ($status eq "Duplicated") {
            $duplicated_genes{$sequence}{$busco_id}++;
        }
    }
    close($fh);
}

# Function to check for commonly duplicated genes across all individuals
sub find_common_duplicated_genes {
    my $num_individuals = shift;

    # Hash to count the frequency of duplicated genes across all samples
    my %common_genes;

    # Check for each sample which genes are duplicated
    foreach my $gene (keys %duplicated_genes) {
        my $num_duplicated = keys %{ $duplicated_genes{$gene} };
        if ($num_duplicated == $num_individuals) {
            $common_genes{$gene} = 1;
        }
    }

    return %common_genes;
}

# Collect all .tsv files in the directory
opendir(my $dh, $busco_dir) or die "Could not open directory $busco_dir: $!";
my @tsv_files = grep { /\.tsv$/ } readdir($dh);
closedir($dh);

# Process each .tsv file
foreach my $tsv_file (@tsv_files) {
    my $full_path = "$busco_dir/$tsv_file";
    process_busco_tsv($full_path);
}

# Number of individuals (number of .tsv files)
my $num_individuals = scalar @tsv_files;

# Find genes commonly duplicated in all individuals
my %common_genes = find_common_duplicated_genes($num_individuals);

# Print the commonly duplicated genes
if (%common_genes) {
    print "Genes commonly duplicated in all $num_individuals individuals:\n";
    foreach my $gene (keys %common_genes) {
        print "$gene\n";
    }
} else {
    print "No commonly duplicated genes found across all individuals.\n";
}
