#!/usr/bin/perl
use strict;
use warnings;

# Core modules
use English;
use FindBin qw( $Bin );

# CPAN modules
use Test::More;
use Test::Deep;
use Test::Exception;

# Project modules
use lib $Bin, "$Bin/../../lib", "$Bin/../../../core/server/t/lib";
use OpenXPKI::Test;

plan tests => 4;

#
# Init helpers
#
my $oxitest = OpenXPKI::Test->new(
    with => [qw( TestRealms CryptoLayer )],
    #log_level => 'trace',
);
my $dbdata = $oxitest->certhelper_database;

use_ok "OpenXPKI::Crypto::CRL"; # this is missing in OpenXPKI::Server::API::Object

$oxitest->insert_testcerts(exclude => ["alpha-signer-2"]);

# unkown issuer
throws_ok {
    my $result = $oxitest->api_command("import_crl" => {
        DATA => $dbdata->crl("alpha-2"),
    });
} qr/I18N_OPENXPKI_UI_IMPORT_CRL_ISSUER_NOT_FOUND/, "import_crl - fails to import CRL with unknown issuer";

$oxitest->insert_testcerts(only => ["alpha-signer-2"]);

# correct import
lives_and {
    my $result = $oxitest->api_command("import_crl" => {
        DATA => $dbdata->crl("alpha-2"),
    });
    cmp_deeply $result, {
        'crl_key' => ignore(),
        'issuer_identifier' => $dbdata->cert("alpha-signer-2")->id,
        'last_update' => ignore(),
        'next_update' => ignore(),
        'pki_realm' => 'alpha',
        'publication_date' => ignore(),
    };
} "import_crl - import CRL";

# duplicate CRL
throws_ok {
    my $result = $oxitest->api_command("import_crl" => {
        DATA => $dbdata->crl("alpha-2"),
    });
} qr/I18N_OPENXPKI_UI_IMPORT_CRL_DUPLICATE/, "import_crl - fails to import the same CRL twice";

$oxitest->delete_testcerts;

1;
