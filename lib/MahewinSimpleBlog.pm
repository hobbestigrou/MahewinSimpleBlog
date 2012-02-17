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
my $comments_directory = Dancer::FileUtils::path(
    setting('appdir'), detail_configuration('comments_directory')
);

my $blog     = MahewinBlogEngine->new();
my $articles = $blog->articles({ directory => $articles_directory });
my $comments = $blog->comments({ directory => $comments_directory });

hook before_template => sub {
    my ( $token ) = @_;

    $token->{config} = list_configuration();
};

get '/' => sub {
    my $get_articles = $articles->article_list;


    foreach my $article (@{$get_articles}) {
        $article->{nb_comments} = scalar(_get_comments_for_article($article->{link}));
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
    my $get_comments_by_article = $comments->get_comments_by_article(params->{title});

    my @comments = _get_comments_for_article(params->{title});
    template 'article_details' => {
        article     => $get_article,
        comments    => \@comments,
        nb_comments => scalar(@comments)
    };
};

post '/comments' => sub {
    return halt('Error: mail is required') if ! params->{email};

    my $params = {
       name   => params->{name},
       mail   => params->{email},
       url    => params->{url},
       body   => params->{body},
       hidden => 1
    };

    $comments->add_comment( params->{id_article}, $params );
    redirect request->base . 'articles/' . params->{id_article};
};

get '/feed' => sub {
    my $get_articles = $articles->article_list;

    _create_feed($get_articles);
};

get '/feed/:tag' => sub {
    my $get_articles = $articles->get_articles_by_tag(params->{tag});

    _create_feed($get_articles);
};

get '/refresh' => sub {
    $articles->clear_articles;
    $comments->clear_comments;

    redirect '/';
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

sub _get_comments_for_article {
    my ( $article ) = @_;

    my $get_comments_by_article = $comments->get_comments_by_article($article);
    my @comments;

    foreach my $comment (@{$get_comments_by_article}) {
        push(@comments, $comment) if $comment->{hidden} == 0;
    }

    return @comments;
}

true;
