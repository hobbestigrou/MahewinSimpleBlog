package MahewinSimpleBlog;
use Dancer ':syntax';

use MahewinBlogEngine;
use Dancer::Plugin::Feed;
use MahewinSimpleBlog::Configuration;

our $VERSION = '0.1';

set public =>  Dancer::FileUtils::path(
    setting('appdir'), 'themes', detail_configuration('themes'), 'public'
);
set views  => Dancer::FileUtils::path(
    setting('appdir'), 'themes', detail_configuration('themes')
);

my $articles_directory = Dancer::FileUtils::path(
    setting('appdir'), detail_configuration('articles_directory')
);

my $blog     = MahewinBlogEngine->new();
my $articles = $blog->articles( directory => $articles_directory );

hook before_template => sub {
    my ( $token ) = @_;

    $token->{config} = list_configuration();
};

get '/' => sub {
    my $get_articles = $articles->article_list;

    if ( params->{page} ) {
        return halt('Attribut page must be an integer')
            if params->{page} !~ /^\d+$/;
    }

    template 'index' => {
        articles         => $get_articles,
        current_page     => params->{page},
        entries_per_page => detail_configuration('articles_per_page') // 5
    };
};

get '/articles/:title' => sub {
    my $get_article = $articles->article_details(params->{title});
    send_error("This articles was deleted or does exist", 404) if ! $get_article;

    template 'article_details' => {
        article     => $get_article,
    };
};

get '/feed' => sub {
    my $get_articles = $articles->article_list;

    _create_feed($get_articles);
};

get '/feed/:tag' => sub {
    my $get_articles = $articles->get_articles_by_tag(params->{tag});

    _create_feed($get_articles);
};

post '/search' => sub {
    my $search_articles = $articles->search(params->{search});

    template 'search' => {
        articles     => $search_articles,
        nb_articles  => scalar(@{$search_articles})
    };
};

sub _create_feed {
    my ( $articles_list ) = @_;

    my @articles_for_feed;
    my $articles_per_feed = detail_configuration('articles_per_feed') // 10;
    my $count             = 0;
    my $url               = request->base;
    $url                  =~ s/:\d+//g;

    foreach my $article ( @{$articles_list} ) {
        my $article_feed = {
            link    => $url . 'articles' . '/' . $article->{link},
            content => $article->{content},
            title   => $article->{title},
            tags    => join(',', @{$article->{tags}})
        };

        push(@articles_for_feed, $article_feed);
        $count++;
        last if $count == $articles_per_feed;
    }

    create_feed(
        format  => detail_configuration('format_feed') // 'rss',
        title   => detail_configuration('blog_name') // 'MahewinSimpleBlog',
        link    => $url,
        entries => \@articles_for_feed,
    );
};

true;
