use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;
use Data::Dumper;

BEGIN { use_ok('RPM::Header::Stream') }

sub process_files {
    my $cb = shift;

    foreach my $filename ( glob File::Spec->catfile( $Bin, '*.hdr' ) ) {
        my $rpm = RPM::Header::Stream->new( debug => 1 );
        my ( $data, $read );
        open my $file, '<', $filename or BAIL_OUT $!;
        eval {
            $read = $rpm->process_chunk();
            while ( $read > 0 ) {
                read( $file, $data, $read ) or die 'nothing to read';
                $read = $rpm->process_chunk($data);
            }
        };
        close $file;
        $cb->( $@, $rpm, $filename );
    }
}

sub rpm2hdr {
    foreach my $filename ( glob File::Spec->catfile( $Bin, "*.rpm" ) ) {
        my $rpm = RPM::Header::Stream->new();
        my ( $data, $read );
        open my $file, '<', $filename or die $!;
        $read = $rpm->process_chunk();
        while ( $read > 0 ) {
            read( $file, $data, $read ) or die 'nothing to read';
            $read = $rpm->process_chunk($data);
        }
        close $file;
        open $file, ">", $filename . ".hdr" or die $!;
        print $file $rpm->get_raw_header();
        close $file;
    }
}

subtest 'new' => sub {
    new_ok('RPM::Header::Stream');
};

subtest 'process_chunk' => sub {
    process_files(
        sub {
            my ( $ret, $rpm, $filename ) = @_;
            my ($base) = ( $filename =~ m{/([^/]+?)\.hdr$} );
            is $ret, '', "$base process done";
        }
    );
};

subtest 'get_hash' => sub {
    my %test = (
        "test_alt_01" =>
          { NAME => "GConf", VERSION => "3.2.3", ARCH => "x86_64" },
        "test_alt_02" => {
            NAME    => "firehol",
            VERSION => "1.282",
            ARCH    => "noarch",
            SOURCE  => [qw(RESERVED_IPS ftp_ssl.conf firehol-1.282.tar)]
        },
        "test_f16_01"  => { NAME => "mlt", VERSION => "0.7.6", ARCH => "i686" },
        "test_suse_01" => { NAME => "mlt", VERSION => "0.2.4", ARCH => "i586" },
    );

    process_files(
        sub {
            my ( $ret, $rpm, $filename ) = @_;
            my $h = $rpm->get_hash;
            my ($base) = ( $filename =~ m{/([^/]+?)\.hdr$} );
            BAIL_OUT "no test for $base" if ( !exists $test{$base} );

            foreach my $tag ( keys %{ $test{$base} } ) {
                my ( $get, $check );
                if ( ref $h->{$tag} eq "ARRAY" ) {
                    $get   = join ",", sort @{ $h->{$tag} };
                    $check = join ",", sort @{ $test{$base}{$tag} };
                }
                else {
                    $get   = $h->{$tag};
                    $check = $test{$base}{$tag};
                }
                is $get, $check, "check $base $tag value";
            }
        }
    );
};

subtest 'get_raw_header' => sub {
    process_files(
        sub {
            my ( $ret, $rpm, $filename ) = @_;
            my $len = length( $rpm->get_raw_header );
            my ($base) = ( $filename =~ m{/([^/]+?)\.hdr$} );
            is( ( stat $filename )[7], $len, "check $base $len length " );
        }
    );
};

done_testing;
