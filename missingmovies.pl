#!/usr/bin/perl
use strict;
use warnings;

use Text::CSV;
use Data::Dumper qw(Dumper);
use Array::Diff;

my $file = $ARGV[0]
    or die "Need to get CSV file on the command line\n";

my $maxMoviesPerUser = 10;
    
read_as_hash($file);

sub read_as_hash {
    my ($filename) = @_;

    my $csv = Text::CSV->new ({
        binary    => 1,
        auto_diag => 1,
        sep_char  => ','
    });

    open(my $data, '<:encoding(utf8)', $filename)
        or die "Could not open '$filename' $!\n";
    my $header = $csv->getline($data);
    $csv->column_names($header);
    my %users;
    my %movies;
    while (my $row = $csv->getline_hr($data)) {
        $users{$row->{'userId'}}{$row->{'movieId'}} = $row->{'movieId'};
        $movies{$row->{'movieId'}} = $row->{'movieId'};
        #print(Dumper %users); print(Dumper %movies); die;
    }

    close $data;

    # write as CSV
    my @missingmovies;
    open(my $fh, '>:encoding(utf8)', 'missingmovies.csv') or die 'missingmovies.csv: $!';
    $csv->say ($fh, $header);
    foreach my $user (sort (keys %users))
    {
        my @usermovies = (keys %{$users{$user}});
        my %diff3 = %movies;
        delete @diff3{ @usermovies };
        my $countMovies = 0;
        foreach my $movie (keys %diff3)
        {
            my(@datarow) = ($user, $movie);
            $csv->say ($fh, \@datarow);
            last if ($countMovies++ == $maxMoviesPerUser);
        }
    }

    close $fh or die "missingmovies.csv: $!";
}

