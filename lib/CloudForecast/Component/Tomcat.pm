package CloudForecast::Component::Tomcat;

use CloudForecast::Component -connector;
use HTTP::Request;

sub port {
    my $self = shift;
    $self->args->[0] || $self->config->{port};
}

sub set {
    my $self = shift;
    $self->config->{user} = 'tomcat' if ( ! defined($self->config->{user}));
    $self->config->{password} = 'admin' if ( ! defined($self->config->{password}));
    $self->config->{content} = '/manager/status' if ( ! defined($self->config->{content}));
    $self->config->{host} = $self->address if ( ! defined($self->config->{host}));
    
    eval {
        unless($self->{content}) {
            $self->{content} = HTTP::Request->new(
                GET => "http://" . $self->address . ":" . $self->port . "/" . $self->config->{content}
            );
            $self->{content}->authorization_basic($self->config->{user},$self->config->{password});
            $self->{content}->header('Host',$self->config->{host});
        }
    };
    die "setting is failed to " . $self->address . ": $@" if $@;
    
    $self->{content};
}

1;
