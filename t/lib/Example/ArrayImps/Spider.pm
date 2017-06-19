package Example::ArrayImps::Spider;

use Moduloop ();

Moduloop->assemble({
    interface => { 
        object => {
            crawl   => {},
            set_url => {},
            url     => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::ArrayImps::Acme::Spider',
});

package Example::ArrayImps::Acme::Spider;

use Moduloop::ArrayImp
    has => { 
        URL => { reader => 'url', writer => 'set_url'  }
    },
;

sub crawl { 
    my ($self, $e) = @_;
    sprintf 'Crawling over %s', $self->url;
}

1;
