#!/usr/bin/perl
use strict;
use Data::Dumper;
use feature 'say';

my %attributes;

sub expand {
    my ($attribute) = @_;
    if (exists $attributes{$attribute}) {
        return $attributes{$attribute}
    }
    else {
        return "{$attribute}"        
    }
}

my %keep = map { $_ => 1 } (qw/
    description
    keywords
    release
    maintenance
    prerelease
    major
    minor
    tabs
/);


sub keep {
    my ($attribute) = @_;

    # we don't need these ones created by assembler
    return if $attribute eq 'page-module';
    return if $attribute eq 'page-relative-src-path';
    return if $attribute =~/^page-origin/;

    return 1 if $attribute =~ /^page-/;
    # return 1 if $attribute =~ /^version(-|$)/;
    # return 1 if $attribute =~ /^vs(-|$)/;
    return 1 if $keep{$attribute};
    return;
}

my $blanks = 0;
my $strip_headings;
my $TABS;

OUTER: while (<>) {
    # expand attributes
    s/\{(\S+?)\}/expand($1)/eg;

    # add new attribute definitions
    if (/^:([a-zA-Z0-9_!-]+):\s*(.*?)\s*$/) {
        my ($k, $v) = ($1, $2);
        if ($k =~ /!/) {
            delete $attributes{$k};
            next;
        }
        elsif ($k eq 'source-language') {
            # print this line BUT also let it be expanded in-place...
            $attributes{$k} = $v;
        }
        elsif (! keep($k)) {
            $attributes{$k} = $v;
            next;
        } 
    }

    # demangle source includes (with additional // include comment at beginning)
    if (/^\[source/) {
        my $source = $_;
        my $delimiter = <>;
        $_ = <>;
        if (/^\/\/ (include::.*)/) {
            my $include = $1;
            $include =~ s/\{(\S+?)\}/expand($1)/eg;

            print $source;
            print $delimiter;
            say $include;
            print $delimiter;
            while (<>) {
                next OUTER if /^$delimiter/;
            }
        } else {
            print $source;
            print $delimiter;
            s/\{(\S+?)\}/expand($1)/eg;
            print;
            next OUTER;
        }
    }

    # de-mangle the {tabs} and plantuml markers
    s/^\[\{?tabs[#}].*\]/[tabs]/;
    s/^\[#.*:::tabs-.*].*$//;
    s/^\[plantum#.*\]/[plantuml]/;

    if ($TABS eq "START") {
        if (/^(=+)/) { $TABS = $1; }
        else { die "Unexpected: $_" }
    }
    elsif ($TABS) {
        s/^\[#[^,]*\]//; # delete broken anchors within tabset
        if (/^$TABS$/) { $TABS = undef; }
    }
    elsif (/^\[tabs/) { $TABS = "START" }


    # images
    s{image::couchbase-lite/current/_images/}{image::ROOT:};
    s{image::couchbase-lite/current/(\w+)/_images/}{image::$1:};

    # de-mangle headings
    if (/^(=+) \S/) {
        s/^===== {empty}/====== {empty}/ or do {
            $strip_headings //= (length $1) - 1;
            s/^={$strip_headings}(=* \S)/$1/;
        }
    }

    # remove spurious passthrough mangling
    s/^pass:q,a\[(.*)\]/$1/;

    # [discrete# mangling
    s/^\[discrete.column/[.column/;
    s/^\[discrete#/[#/;
    s/^\[discret#(.*)e\]/[discrete#$1/;

    # get rid of '// Define our environment' comments in calling pages
    s/^\/\/ Define.*//;

    # de-mangle ::: links in block headers, #fragments, and <<links>>
    s/\[.column.*\]/[.column]/;
    s/#\S*:::/#/;
    s/<<.*?:::/<</g;
    s/^\[#?\].*$//;

    # don't print more than 2 blank lines in a row
    if (length == 1) {
        next if $blanks++ >= 2;
    } else {
        $blanks = 0;
    }

    # print lines that we didn't swallow as attribute definitions
    print;
}
