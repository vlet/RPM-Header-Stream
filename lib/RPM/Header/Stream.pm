package RPM::Header::Stream;
use strict;
use warnings;
use Carp;

our $VERSION = '0.010';

use constant RPM_FILE_MAGIC => pack( 'C4', 0xed, 0xab, 0xee, 0xdb );
use constant RPM_HEADER_MAGIC => pack( 'C3', 0x8e, 0xad, 0xe8 );
use constant LEAD_SIZE        => 96;
use constant INDEX_SIZE       => 16;

my %rpmtag = (
    63   => { 'TAGNAME' => 'HEADER_IMMUTABLE',  'TYPE' => 1 },
    100  => { 'TAGNAME' => 'HEADER_I18NTABLE',  'TYPE' => 1 },
    1000 => { 'TAGNAME' => 'NAME' },
    1001 => { 'TAGNAME' => 'VERSION' },
    1002 => { 'TAGNAME' => 'RELEASE' },
    1003 => { 'TAGNAME' => 'EPOCH' },
    1004 => { 'TAGNAME' => 'SUMMARY',           'TYPE' => 1 },
    1005 => { 'TAGNAME' => 'DESCRIPTION',       'TYPE' => 1 },
    1006 => { 'TAGNAME' => 'BUILDTIME' },
    1007 => { 'TAGNAME' => 'BUILDHOST' },
    1008 => { 'TAGNAME' => 'INSTALLTIME' },
    1009 => { 'TAGNAME' => 'SIZE' },
    1010 => { 'TAGNAME' => 'DISTRIBUTION' },
    1011 => { 'TAGNAME' => 'VENDOR' },
    1012 => { 'TAGNAME' => 'GIF' },
    1013 => { 'TAGNAME' => 'XPM' },
    1014 => { 'TAGNAME' => 'LICENSE' },
    1015 => { 'TAGNAME' => 'PACKAGER' },
    1016 => { 'TAGNAME' => 'GROUP' },
    1017 => { 'TAGNAME' => 'CHANGELOG' },
    1018 => { 'TAGNAME' => 'SOURCE',            'TYPE' => 1 },
    1019 => { 'TAGNAME' => 'PATCH',             'TYPE' => 1 },
    1020 => { 'TAGNAME' => 'URL' },
    1021 => { 'TAGNAME' => 'OS' },
    1022 => { 'TAGNAME' => 'ARCH' },
    1023 => { 'TAGNAME' => 'PREIN',             'TYPE' => 1 },
    1024 => { 'TAGNAME' => 'POSTIN',            'TYPE' => 1 },
    1025 => { 'TAGNAME' => 'PREUN',             'TYPE' => 1 },
    1026 => { 'TAGNAME' => 'POSTUN',            'TYPE' => 1 },
    1027 => { 'TAGNAME' => 'OLDFILENAMES',      'TYPE' => 1 },
    1028 => { 'TAGNAME' => 'FILESIZES',         'TYPE' => 1 },
    1029 => { 'TAGNAME' => 'FILESTATES',        'TYPE' => 1 },
    1030 => { 'TAGNAME' => 'FILEMODES',         'TYPE' => 1 },
    1031 => { 'TAGNAME' => 'FILEUIDS' },
    1032 => { 'TAGNAME' => 'FILEGIDS' },
    1033 => { 'TAGNAME' => 'FILERDEVS',         'TYPE' => 1 },
    1034 => { 'TAGNAME' => 'FILEMTIMES',        'TYPE' => 1 },
    1035 => { 'TAGNAME' => 'FILEMD5S',          'TYPE' => 1 },
    1036 => { 'TAGNAME' => 'FILELINKTOS',       'TYPE' => 1 },
    1037 => { 'TAGNAME' => 'FILEFLAGS',         'TYPE' => 1 },
    1038 => { 'TAGNAME' => 'ROOT' },
    1039 => { 'TAGNAME' => 'FILEUSERNAME',      'TYPE' => 1 },
    1040 => { 'TAGNAME' => 'FILEGROUPNAME',     'TYPE' => 1 },
    1041 => { 'TAGNAME' => 'EXCLUDE' },
    1042 => { 'TAGNAME' => 'EXCLUSIVE' },
    1043 => { 'TAGNAME' => 'ICON' },
    1044 => { 'TAGNAME' => 'SOURCERPM' },
    1045 => { 'TAGNAME' => 'FILEVERIFYFLAGS',   'TYPE' => 1 },
    1046 => { 'TAGNAME' => 'ARCHIVESIZE' },
    1047 => { 'TAGNAME' => 'PROVIDENAME',       'TYPE' => 1 },
    1048 => { 'TAGNAME' => 'REQUIREFLAGS',      'TYPE' => 1 },
    1049 => { 'TAGNAME' => 'REQUIRENAME',       'TYPE' => 1 },
    1050 => { 'TAGNAME' => 'REQUIREVERSION',    'TYPE' => 1 },
    1051 => { 'TAGNAME' => 'NOSOURCE' },
    1052 => { 'TAGNAME' => 'NOPATCH' },
    1053 => { 'TAGNAME' => 'CONFLICTFLAGS',     'TYPE' => 1 },
    1054 => { 'TAGNAME' => 'CONFLICTNAME',      'TYPE' => 1 },
    1055 => { 'TAGNAME' => 'CONFLICTVERSION',   'TYPE' => 1 },
    1056 => { 'TAGNAME' => 'DEFAULTPREFIX' },
    1057 => { 'TAGNAME' => 'BUILDROOT',         'TYPE' => 1 },
    1058 => { 'TAGNAME' => 'INSTALLPREFIX' },
    1059 => { 'TAGNAME' => 'EXCLUDEARCH' },
    1060 => { 'TAGNAME' => 'EXCLUDEOS' },
    1061 => { 'TAGNAME' => 'EXCLUSIVEARCH',     'TYPE' => 1 },
    1062 => { 'TAGNAME' => 'EXCLUSIVEOS' },
    1063 => { 'TAGNAME' => 'AUTOREQPROV' },
    1064 => { 'TAGNAME' => 'RPMVERSION' },
    1065 => { 'TAGNAME' => 'TRIGGERSCRIPTS',    'TYPE' => 1 },
    1066 => { 'TAGNAME' => 'TRIGGERNAME',       'TYPE' => 1 },
    1067 => { 'TAGNAME' => 'TRIGGERVERSION',    'TYPE' => 1 },
    1068 => { 'TAGNAME' => 'TRIGGERFLAGS',      'TYPE' => 1 },
    1069 => { 'TAGNAME' => 'TRIGGERINDEX',      'TYPE' => 1 },
    1079 => { 'TAGNAME' => 'VERIFYSCRIPT',      'TYPE' => 1 },
    1080 => { 'TAGNAME' => 'CHANGELOGTIME',     'TYPE' => 1 },
    1081 => { 'TAGNAME' => 'CHANGELOGNAME',     'TYPE' => 1 },
    1082 => { 'TAGNAME' => 'CHANGELOGTEXT',     'TYPE' => 1 },
    1083 => { 'TAGNAME' => 'BROKENMD5' },
    1084 => { 'TAGNAME' => 'PREREQ' },
    1085 => { 'TAGNAME' => 'PREINPROG',         'TYPE' => 1 },
    1086 => { 'TAGNAME' => 'POSTINPROG',        'TYPE' => 1 },
    1087 => { 'TAGNAME' => 'PREUNPROG',         'TYPE' => 1 },
    1088 => { 'TAGNAME' => 'POSTUNPROG',        'TYPE' => 1 },
    1089 => { 'TAGNAME' => 'BUILDARCHS',        'TYPE' => 1 },
    1090 => { 'TAGNAME' => 'OBSOLETENAME',      'TYPE' => 1 },
    1091 => { 'TAGNAME' => 'VERIFYSCRIPTPROG',  'TYPE' => 1 },
    1092 => { 'TAGNAME' => 'TRIGGERSCRIPTPROG', 'TYPE' => 1 },
    1093 => { 'TAGNAME' => 'DOCDIR' },
    1094 => { 'TAGNAME' => 'COOKIE' },
    1095 => { 'TAGNAME' => 'FILEDEVICES',       'TYPE' => 1 },
    1096 => { 'TAGNAME' => 'FILEINODES',        'TYPE' => 1 },
    1097 => { 'TAGNAME' => 'FILELANGS',         'TYPE' => 1 },
    1098 => { 'TAGNAME' => 'PREFIXES',          'TYPE' => 1 },
    1099 => { 'TAGNAME' => 'INSTPREFIXES',      'TYPE' => 1 },
    1100 => { 'TAGNAME' => 'TRIGGERIN' },
    1101 => { 'TAGNAME' => 'TRIGGERUN' },
    1102 => { 'TAGNAME' => 'TRIGGERPOSTUN' },
    1103 => { 'TAGNAME' => 'AUTOREQ' },
    1104 => { 'TAGNAME' => 'AUTOPROV' },
    1105 => { 'TAGNAME' => 'CAPABILITY' },
    1106 => { 'TAGNAME' => 'SOURCEPACKAGE' },
    1107 => { 'TAGNAME' => 'OLDORIGFILENAMES' },
    1108 => { 'TAGNAME' => 'BUILDPREREQ' },
    1109 => { 'TAGNAME' => 'BUILDREQUIRES' },
    1110 => { 'TAGNAME' => 'BUILDCONFLICTS' },
    1111 => { 'TAGNAME' => 'BUILDMACROS' },
    1112 => { 'TAGNAME' => 'PROVIDEFLAGS',      'TYPE' => 1 },
    1113 => { 'TAGNAME' => 'PROVIDEVERSION',    'TYPE' => 1 },
    1114 => { 'TAGNAME' => 'OBSOLETEFLAGS',     'TYPE' => 1 },
    1115 => { 'TAGNAME' => 'OBSOLETEVERSION',   'TYPE' => 1 },
    1116 => { 'TAGNAME' => 'DIRINDEXES',        'TYPE' => 1 },
    1117 => { 'TAGNAME' => 'BASENAMES',         'TYPE' => 1 },
    1118 => { 'TAGNAME' => 'DIRNAMES',          'TYPE' => 1 },
    1119 => { 'TAGNAME' => 'ORIGDIRINDEXES' },
    1120 => { 'TAGNAME' => 'ORIGBASENAMES' },
    1121 => { 'TAGNAME' => 'ORIGDIRNAMES' },
    1122 => { 'TAGNAME' => 'OPTFLAGS',          'TYPE' => 1 },
    1123 => { 'TAGNAME' => 'DISTURL' },
    1124 => { 'TAGNAME' => 'PAYLOADFORMAT',     'TYPE' => 1 },
    1125 => { 'TAGNAME' => 'PAYLOADCOMPRESSOR', 'TYPE' => 1 },
    1126 => { 'TAGNAME' => 'PAYLOADFLAGS',      'TYPE' => 1 },
    1127 => { 'TAGNAME' => 'MULTILIBS' },
    1128 => { 'TAGNAME' => 'INSTALLTID' },
    1129 => { 'TAGNAME' => 'REMOVETID' },
    1130 => { 'TAGNAME' => 'SHA1RHN' },
    1131 => { 'TAGNAME' => 'RHNPLATFORM',       'TYPE' => 1 },
    1132 => { 'TAGNAME' => 'PLATFORM',          'TYPE' => 1 },
    1133 => { 'TAGNAME' => 'PATCHESNAME' },
    1134 => { 'TAGNAME' => 'PATCHESFLAGS' },
    1135 => { 'TAGNAME' => 'PATCHESVERSION' },
    1136 => { 'TAGNAME' => 'CACHECTIME' },
    1137 => { 'TAGNAME' => 'CACHEPKGPATH' },
    1138 => { 'TAGNAME' => 'CACHEPKGSIZE' },
    1139 => { 'TAGNAME' => 'CACHEPKGMTIME' },
    1140 => { 'TAGNAME' => 'FILECOLORS',        'TYPE' => 1 },
    1141 => { 'TAGNAME' => 'FILECLASS',         'TYPE' => 1 },
    1142 => { 'TAGNAME' => 'CLASSDICT',         'TYPE' => 1 },
    1143 => { 'TAGNAME' => 'FILEDEPENDSX',      'TYPE' => 1 },
    1144 => { 'TAGNAME' => 'FILEDEPENDSN',      'TYPE' => 1 },
    1145 => { 'TAGNAME' => 'DEPENDSDICT',       'TYPE' => 1 },
    1146 => { 'TAGNAME' => 'SOURCEPKGID',       'TYPE' => 1 },
    1152 => { 'TAGNAME' => 'POSTTRANS' },
    1154 => { 'TAGNAME' => 'POSTTRANSPROG' },
    5011 => { 'TAGNAME' => 'FILEDIGESTALGOS' },
);

my %rpmtag_sig = (
    62   => { 'TAGNAME' => 'HEADER_SIGNATURES', 'TYPE' => 1 },
    265  => { 'TAGNAME' => 'BADSHA1_2',         'TYPE' => 1 },
    267  => { 'TAGNAME' => 'DSAHEADER',         'TYPE' => 1 },
    268  => { 'TAGNAME' => 'RSAHEADER',         'TYPE' => 1 },
    269  => { 'TAGNAME' => 'SHA1HEADER',        'TYPE' => 1 },
    1000 => { 'TAGNAME' => 'SIGSIZE',           'TYPE' => 1 },
    1001 => { 'TAGNAME' => 'SIGLEMD5_1',        'TYPE' => 1 },
    1002 => { 'TAGNAME' => 'SIGPGP',            'TYPE' => 1 },
    1003 => { 'TAGNAME' => 'SIGLEMD5_2',        'TYPE' => 1 },
    1004 => { 'TAGNAME' => 'SIGMD5',            'TYPE' => 1 },
    1005 => { 'TAGNAME' => 'SIGGPG',            'TYPE' => 1 },
    1006 => { 'TAGNAME' => 'SIGPGP5' },
    1007 => { 'TAGNAME' => 'SIGPAYLOADSIZE' },
);

sub _debug {
    my ( $self, $level, $str ) = @_;
    if ( $self->{debug} >= $level ) {
        print STDERR $str, "\n";
    }
}

sub _unpack_lead {
    my $self = shift;
    (
        $self->{'hash'}->{'LEAD_MAGIC'},   # unsigned char[4], í«îÛ == rpm
        $self->{'hash'}->{'LEAD_MAJOR'},   # unsigned char, 3 == rpm version 3.x
        $self->{'hash'}->{'LEAD_MINOR'},   # unsigned char, 0 == rpm version x.0
        $self->{'hash'}->{'LEAD_TYPE'}, # short(int16), 0 == binary, 1 == source
        $self->{'hash'}->{'LEAD_ARCHNUM'},       # short(int16), 1 == i386
        $self->{'hash'}->{'LEAD_NAME'},          # char[66], rpm name
        $self->{'hash'}->{'LEAD_OSNUM'},         # short(int16), 1 == Linux
        $self->{'hash'}->{'LEAD_SIGNATURETYPE'}, # short(int16), 1280 == rpm 4.0
        $self->{'hash'}->{'LEAD_RESERVED'}       # char[16] future expansion
    ) = unpack( 'a4CCssA66ssA16', substr( $self->{data}, 0, LEAD_SIZE ) );
    if ( $self->{'hash'}->{'LEAD_MAGIC'} ne RPM_FILE_MAGIC ) {
        croak 'Invalid rpm file magic';
    }
}

sub _unpack_header {
    my $self = shift;
    my (
        $header_magic,   $header_version, $header_reserved,
        $header_entries, $header_size
      )
      = unpack( 'a3CNNN',
        substr( $self->{data}, $self->{offset}, INDEX_SIZE ) );

    if ( $header_magic ne RPM_HEADER_MAGIC ) {
        croak 'Invalid header magic at offset ' . $self->{offset};
    }

    my $offset =
      $self->{offset} +
      INDEX_SIZE +
      $header_entries * INDEX_SIZE +
      $header_size;

    return ( $header_entries, $header_size, $offset );
}

sub _process_header {
    my $self           = shift;
    my $header_entries = shift;
    my $buff_offset    = $self->{offset} + $header_entries * INDEX_SIZE;

    # signature/header
    my $tags =
      ( $self->{offset} == LEAD_SIZE + INDEX_SIZE )
      ? \%rpmtag_sig
      : \%rpmtag;

    for my $record_num ( 0 .. $header_entries - 1 ) {
        my ( $tag, $type, $offset, $count ) = unpack(
            'NNNN',
            substr(
                $self->{data}, $self->{offset} + $record_num * INDEX_SIZE,
                INDEX_SIZE
            )
        );

        $self->_debug( 2,
                "Process TAG: $tags->{$tag}->{TAGNAME} ($tag), "
              . "TYPE: $type, OFFSET: $offset, COUNT: $count" );
        my @value;

        # Unknown tag
        if ( !exists $tags->{$tag} ) {
            $self->_debug( 1,
                "Unknown TAG: $tag, TYPE: $type, OFFSET: $offset, COUNT: $count"
            );
            $tags->{$tag}->{TAGNAME} = 'UNKNOWN_' . $tag;
        }

        # Null type
        if ( $type == 0 ) {
            @value = ('');
        }

        # Char type
        elsif ( $type == 1 ) {
            croak "Char type not supported: $tags->{$tag}{'TAGNAME'}, $count";
        }

        # int8
        elsif ( $type == 2 ) {
            @value =
              unpack( 'C*',
                substr( $self->{data}, $buff_offset + $offset, 1 * $count ) );
        }

        # int16
        elsif ( $type == 3 ) {
            @value =
              unpack( 'n*',
                substr( $self->{data}, $buff_offset + $offset, 2 * $count ) );
        }

        # int32
        elsif ( $type == 4 ) {
            @value =
              unpack( 'N*',
                substr( $self->{data}, $buff_offset + $offset, 4 * $count ) );
        }

        # int64
        elsif ( $type == 5 ) {
            croak
              "Int64 type not supported : $tags->{$tag}->{'TAGNAME'}, $count";
        }

        # String, String array, I18N string array
        elsif ( $type == 6 or $type == 8 or $type == 9 ) {
            for ( 1 .. $count ) {
                my $length =
                  index( $self->{data}, "\0", $buff_offset + $offset ) -
                  ( $buff_offset + $offset );

                # unpack istedet for substr.
                push @value,
                  substr( $self->{data}, $buff_offset + $offset, $length );
                $offset += $length + 1;
            }
        }

        # bin
        elsif ( $type == 7 ) {
            $value[0] = substr( $self->{data}, $buff_offset + $offset, $count );
        }

        # Find out if it's an array type or not.
        if ( defined( $tags->{$tag}{'TYPE'} ) and $tags->{$tag}{'TYPE'} == 1 ) {
            $self->{'hash'}->{ $tags->{$tag}->{'TAGNAME'} } = [@value];
        }
        else {
            if ( $count > 1 ) {
                $self->_debug( 1,
                        "tag = $tags->{$tag}->{'TAGNAME'}, "
                      . "type = $type, count = $count" );
            }
            $self->{'hash'}->{ $tags->{$tag}->{'TAGNAME'} } = $value[0];
        }
    }
}

sub new {
    my ( $class, %opts ) = @_;
    bless {
        hash   => {},
        data   => '',
        offset => 0,
        debug  => ( exists $opts{debug} ) ? $opts{debug} : 0,
    }, $class;
}

sub process_chunk {
    my ( $self, $data ) = @_;

    if ( defined $data ) {
        $self->{data} .= $data;
    }

    my $len = length( $self->{data} );

    # Unpack LEAD
    if ( $self->{offset} == 0 ) {
        if ( $len < LEAD_SIZE ) {
            return LEAD_SIZE + INDEX_SIZE - $len;
        }
        $self->_unpack_lead();
        $self->{offset} = LEAD_SIZE;
    }

    # Unpack Signature
    if ( $self->{offset} == LEAD_SIZE ) {
        if ( $len < $self->{offset} + INDEX_SIZE ) {
            return $self->{offset} + INDEX_SIZE - $len;
        }
        my ( $header_entries, $header_size, $offset ) = $self->_unpack_header();

        # padding to an 8-byte boundary
        if ( ( $header_size % 8 ) != 0 ) {
            $offset += 8 - ( $header_size % 8 );
        }

        if ( $len < $offset ) {
            return $offset - $len + INDEX_SIZE;
        }

        $self->{offset} += INDEX_SIZE;
        $self->_process_header($header_entries);
        $self->{offset} = $offset;
    }

    # Unpack Header
    if ( $len < $self->{offset} + INDEX_SIZE ) {
        return $self->{offset} + INDEX_SIZE - $len;
    }
    my ( $header_entries, $header_size, $offset ) = $self->_unpack_header();

    if ( $len < $offset ) {
        return $offset - $len;
    }

    $self->{offset} += INDEX_SIZE;
    $self->_process_header($header_entries);
    $self->{offset} = $offset;

    $self->{data} = substr( $self->{data}, 0, $offset );

    return 0;
}

sub get_raw_header {
    my $self = shift;
    return $self->{data};
}

sub get_hash {
    my $self = shift;
    return $self->{hash};
}

1;
__END__

=head1 NAME

RPM::Header::Stream - pure perl RPM header stream reader

=head1 SYNOPSIS

    use RPM::Header::Stream;
    use Data::Dumper;

    my ( $read, $data );
    my $rpm = RPM::Header::Stream->new( debug => 0 );

    eval {

        # Open rpm file
        open my $file, '<', 'rpm-4.0.4-alt98.9.src.rpm' or die $!;

        # process_chunk() returned size in bytes
        # needed to complete reading next header
        # or 0 if reading complete
        $read = $rpm->process_chunk();

        while ($read > 0) {
            read($file, $data, $read) or die 'nothing to read';
            $read = $rpm->process_chunk($data);
        }
        close $file;
    };

    if ($@) {
        warn 'Error while processing rpm header: ' . $@;
        exit;
    }

    # print hash with RPM TAGs
    print Dumper $rpm->get_hash;

    # store raw RPM header into file
    open my $file, '>', 'rpm.header' or die $!;
    print $file $rpm->get_raw_header;
    close $file;

=head1 DESCRIPTION

RPM::Header::Stream is alternative implementation of RPM::Header written in only Perl.
It's based on RPM::Header::PurePerl, but adopted to work with RPM5 and ALTLinux fork of RPM.

=head1 EXPORT

None by default.

=head1 PUBLIC METHODS

=head2 new ( %options ) 

create RPM::Header::Stream object

    # 2 - heavy debuging
    # 1 - warns on unknown tags
    # 0 - no debuging
    my $rpm = RPM::Header::Stream->new( debug => 2 );

=head2 process_chunk ( $data )

process another chunk of RPM file stored in $data, returned size in bytes
needed to complete reading next header or 0 if reading complete
 
=head2 get_hash

return ref to hash where keys are RPM TAGS

=head2 get_raw_header

return raw rpm header.
this can be stored in file and analyzed again.

=head1 SEE ALSO

=over

=item https://metacpan.org/module/RPM::Header::PurePerl

=item http://www.rpm.org/max-rpm/s1-rpm-file-format-rpm-file-format.html

=item http://rpm5.org/cvs/fileview?f=rpm/rpmdb/tag.asn

=back

=head1 AUTHOR

Vladimir Lettiev <crux@cpan.org>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2001,2002,2006 Troels Liebe Bentsen (RPM::Header::PurePerl)

=item Copyright (C) 2009,2011 Vladimir Lettiev

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
