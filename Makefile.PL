use inc::Module::Install;

name 'RPM-Header-Stream';
all_from 'lib/RPM/Header/Stream.pm';

test_requires 'Test::More';
test_requires 'File::Spec';
test_requires 'Data::Dumper';

WriteAll;
