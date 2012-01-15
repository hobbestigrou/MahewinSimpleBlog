package MahewinSimpleBlog::Configuration;

use Dancer ':syntax';
use Dancer::Plugin;

register list_configuration => sub {
    return plugin_setting;
};

register detail_configuration => sub {
    my ( $param ) = shift;
    my $settings  = plugin_setting;

    return $settings->{$param};
};

register_plugin;

1;
