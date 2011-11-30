Name: perl-RPM-Header-Stream
Version: 0.010
Release: alt1
Summary: RPM::Header::Stream - pure perl RPM header stream reader

Group: Development/Perl
License: Perl
Url: %CPAN RPM-Header-Stream

BuildArch: noarch
Source: %name-%version.tar
BuildRequires: perl-devel perl-Module-Install

%description
%summary

%prep
%setup -q

%build
%perl_vendor_build

%install
%perl_vendor_install

%files
%perl_vendor_privlib/RPM/Header/Stream.pm
%doc Changes

%changelog
* Wed Nov 30 2011 Vladimir Lettiev <crux@altlinux.ru> 0.010-alt1
- 0.010
- initial build

