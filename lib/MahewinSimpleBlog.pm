package MahewinSimpleBlog;
use Dancer ':syntax';

use Text::Simple::Blog;
use Dancer::Plugin::Feed;

use Try::Tiny;

our $VERSION = '0.1';

my $articles_directory = Dancer::FileUtils::path(
    setting('appdir'), setting('articles_directory')
);
my $comments_directory = Dancer::FileUtils::path(
    setting('appdir'), setting('comments_directory')
);

my $blog     = Text::Simple::Blog->new();
my $articles = $blog->articles({ directory => $articles_directory });
my $comments = $blog->comments({ directory => $comments_directory });

get '/' => sub {
    my $get_articles = $articles->articles;

    template 'index' => {
        articles         => $get_articles,
        current_page     => params->{page},
        entries_per_page => 5
    };

};

get '/articles/:title' => sub {
    my $get_article = $articles->get_article(params->{title});
    my $get_comments_by_article = $comments->get_comments_by_article(params->{title});

    my @comments;
    foreach my $comment (@{$get_comments_by_article}) {
        push(@comments, $comment) if $comment->{hidden} == 0;
    }

    template 'article_details' => {
        article     => $get_article,
        comments    => \@comments,
        nb_comments => scalar(@comments)
    };
};

post '/comments' => sub {
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
    my $get_articles = $articles->articles;

    my @articles_for_feed;
    my $count = 0;
    foreach my $article (@{$get_articles}) {
        push(@articles_for_feed, $article);
        $count++;
        last if $count == 10;
    }

    create_feed(
            format  => 'rss',
            title   => 'Hobbestigrou ',
            link    => request->base,
            entries => \@articles_for_feed,
        );
};

get '/feed/:tag' => sub {
    my $get_articles = $articles->get_articles_by_tag(params->{tag});

    my @articles_for_feed;
    my $count = 0;
    foreach my $article (@{$get_articles}) {
        push(@articles_for_feed, $article);
        $count++;
        last if $count == 10;
    }

    create_feed(
            format  => 'rss',
            title   => 'Hobbestigrou ',
            link    => request->base,
            entries => \@articles_for_feed,
        );
};

true;
