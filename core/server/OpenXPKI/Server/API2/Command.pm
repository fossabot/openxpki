package OpenXPKI::Server::API2::Command;
=head1 Name

OpenXPKI::Server::API2::CommandRole

=cut
use Moose;
use Moose::Exporter;
use Moose::Util;

use OpenXPKI::Server::API2::CommandRole;



Moose::Exporter->setup_import_methods(
    with_meta => [ "param" ],
    also => "Moose",
);

sub init_meta {
    shift; # our class name
    my %args = @_;

    Moose->init_meta(%args);

    Moose::Util::apply_all_roles($args{for_class}, 'OpenXPKI::Server::API2::CommandRole');

    return $args{for_class}->meta();
}

sub param {
    my ($meta, $name, %spec) = @_;

    if ($spec{matching}) {
        # FIXME Implement
        delete $spec{matching};
    }

    $meta->add_attribute($name,
        is => 'ro',
        %spec,
    );
}

1;
